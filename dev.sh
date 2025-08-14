#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Cleanup function for signal handling
cleanup() {
    print_status "Cleaning up development environment..."
    
    # Stop docker containers
    if docker-compose -f backend/docker-compose.yml ps -q | grep -q .; then
        print_status "Stopping Docker containers..."
        docker-compose -f backend/docker-compose.yml down
    fi
    
    # Stop iOS simulator if running
    if check_ios_tools; then
        local running_devices=$(xcrun simctl list devices booted | grep "iPhone" | wc -l)
        if [ "$running_devices" -gt 0 ]; then
            print_status "Shutting down iOS simulators..."
            xcrun simctl shutdown booted
        fi
    fi
    
    print_success "Cleanup completed"
    exit 0
}

# Set up signal traps for cleanup
trap cleanup SIGINT SIGTERM

# Load environment
load_env() {
    if [ ! -f ".env" ]; then
        print_warning "No .env found, creating from template..."
        cp .env.example .env
        print_status "Edit .env to add API keys (optional)"
    fi
    export $(cat .env | grep -v '#' | grep -v '^$' | xargs)
}

# Check prerequisites
check_prerequisites() {
    # Check Docker
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker not running. Please start Docker Desktop."
        exit 1
    fi
    
    # Check Go (required for building Lambda functions)
    if ! command -v go >/dev/null 2>&1; then
        print_error "Go not found. Please install Go to build Lambda functions."
        print_status "Install options:"
        print_status "  • macOS: brew install go"
        print_status "  • Download: https://golang.org/dl/"
        print_status ""
        print_status "Or continue without building (LocalStack will still work):"
        read -p "Continue without Go? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        return 1
    fi
    
    print_success "Prerequisites check passed"
    return 0
}

# Check if iOS development tools are available
check_ios_tools() {
    if command -v xcrun >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Start iOS simulator and app
start_ios() {
    if ! check_ios_tools; then
        print_warning "Xcode tools not available - skipping iOS simulator"
        return 1
    fi
    
    print_status "Starting iOS Simulator..."
    
    # Get the first available iPhone simulator
    local device_id=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
    
    if [ -z "$device_id" ]; then
        print_error "No iPhone simulators available"
        return 1
    fi
    
    # Boot the simulator if not already running
    xcrun simctl boot "$device_id" 2>/dev/null || true
    
    # Open Simulator app
    open -a Simulator
    
    # Wait a moment for simulator to start
    sleep 3
    
    # Build and install the app
    print_status "Building and installing InnerWorld app..."
    print_status "(This may take several minutes on first run - downloading dependencies...)"
    cd ios
    
    # Clean previous builds for reliability
    print_status "Cleaning previous builds..."
    xcodebuild -project InnerWorld.xcodeproj -scheme InnerWorld -destination "id=$device_id" clean >/dev/null 2>&1 || true
    
    # Build with more verbose output for debugging
    print_status "Compiling iOS app..."
    if xcodebuild -project InnerWorld.xcodeproj -scheme InnerWorld -destination "id=$device_id" -configuration Debug -derivedDataPath build -allowProvisioningUpdates; then
        print_success "iOS build completed successfully"
        
        # Find the built app
        local app_path=$(find build -name "InnerWorld.app" -path "*/Debug-iphonesimulator/*" | head -1)
        if [ -n "$app_path" ] && [ -d "$app_path" ]; then
            print_status "Installing app on simulator..."
            xcrun simctl install "$device_id" "$app_path"
            print_success "InnerWorld app installed on simulator"
            
            # Wait for installation to complete
            sleep 2
            
            # Launch the app
            print_status "Launching InnerWorld app..."
            if xcrun simctl launch "$device_id" com.thoughtmanifold.InnerWorld; then
                print_success "InnerWorld app launched successfully"
            else
                print_warning "App installed but launch failed - you can launch manually from simulator"
            fi
        else
            print_warning "Build succeeded but app not found at expected location"
        fi
    else
        print_warning "Failed to build iOS app - you can build manually in Xcode"
        print_status "Try running: cd ios && xcodebuild -project InnerWorld.xcodeproj -scheme InnerWorld"
    fi
    cd ..
    
    return 0
}

# Check if services are running
is_running() {
    docker-compose -f backend/docker-compose.yml ps -q | grep -q . 2>/dev/null
}

# Start development environment
start_dev() {
    print_status "Starting InnerWorld development environment..."
    
    load_env
    
    # Check prerequisites
    if check_prerequisites; then
        GO_AVAILABLE=true
    else
        GO_AVAILABLE=false
        print_warning "Continuing without Go - Lambda functions won't be built locally"
    fi
    
    # Check for --with-ios flag
    if [ "$1" = "--with-ios" ]; then
        START_IOS=true
    else
        START_IOS=false
    fi
    
    # Start LocalStack (only service we need)
    print_status "Starting LocalStack..."
    cd backend && docker-compose up -d && cd ..
    
    # Wait for LocalStack
    print_status "Waiting for LocalStack..."
    for i in {1..30}; do
        # Check if container is healthy (more reliable than HTTP check)
        if docker inspect innerworld-localstack --format='{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
            print_success "LocalStack container is healthy"
            
            # Try HTTP health check as secondary verification
            if curl -f http://localhost:4566/_localstack/health >/dev/null 2>&1; then
                print_success "LocalStack HTTP endpoint is ready"
            else
                print_warning "LocalStack container healthy but HTTP endpoint not accessible from host"
                print_status "This may be a Docker networking issue but LocalStack should work"
            fi
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "LocalStack container failed to become healthy"
            print_status "Checking container status..."
            docker-compose -f backend/docker-compose.yml ps
            print_status "Checking LocalStack logs..."
            docker logs innerworld-localstack --tail 20
            exit 1
        fi
        printf "."
        sleep 2
    done
    
    # Build backend functions (if Go is available)
    if [ "$GO_AVAILABLE" = true ]; then
        print_status "Building backend functions..."
        cd backend && make build && cd ..
    else
        print_warning "Skipping backend build (Go not available)"
    fi
    
    # Start iOS if requested
    if [ "$START_IOS" = true ]; then
        if start_ios; then
            IOS_RUNNING=true
        else
            IOS_RUNNING=false
        fi
    else
        IOS_RUNNING=false
    fi
    
    print_success "Development environment ready!"
    echo ""
    echo "🌐 Services:"
    if [ "$GO_AVAILABLE" = true ]; then
        echo "   • Backend API: http://localhost:3000 (use 'make test-sam-api' in backend/)"
        echo "   • Health Check: http://localhost:3000/health"  
    else
        echo "   • Backend API: Not available (Go not installed)"
        echo "   • Health Check: Not available (Go not installed)"
    fi
    echo "   • LocalStack: http://localhost:4566"
    if [ "$IOS_RUNNING" = true ]; then
        echo "   • iOS App: Running in Simulator"
    elif [ "$START_IOS" = true ]; then
        echo "   • iOS App: Failed to start"
    else
        echo "   • iOS App: Not started (use --with-ios flag)"
    fi
    echo ""
    echo "🧪 Testing:"
    echo "   • ./dev.sh test"
    if [ "$GO_AVAILABLE" != true ]; then
        echo ""
        echo "💡 To enable Lambda functions:"
        echo "   • Install Go: brew install go"
        echo "   • Restart: ./dev.sh restart"
    fi
    if [ "$IOS_RUNNING" != true ] && check_ios_tools; then
        echo ""
        echo "📱 To start with iOS:"
        echo "   • ./dev.sh restart --with-ios"
    fi
    echo ""
    echo "🛑 Stop:"
    echo "   • ./dev.sh stop"
}

# Stop development environment  
stop_dev() {
    print_status "Stopping InnerWorld development environment..."
    
    # Stop docker containers
    if docker-compose -f backend/docker-compose.yml ps -q | grep -q .; then
        print_status "Stopping Docker containers..."
        docker-compose -f backend/docker-compose.yml down
    else
        print_status "No Docker containers running"
    fi
    
    # Note about iOS simulator (don't auto-stop as user might want to keep it running)
    if check_ios_tools; then
        local running_devices=$(xcrun simctl list devices booted | grep "iPhone" | wc -l)
        if [ "$running_devices" -gt 0 ]; then
            print_status "iOS simulator still running (use Ctrl+C for full cleanup)"
        fi
    fi
    
    print_success "Development environment stopped"
}

# Test services
test_dev() {
    print_status "Testing development services..."
    
    # Test LocalStack (try container health as fallback)
    if curl -f http://localhost:4566/_localstack/health >/dev/null 2>&1; then
        print_success "LocalStack HTTP: OK"
    elif docker inspect innerworld-localstack --format='{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
        print_success "LocalStack Container: Healthy (HTTP endpoint not accessible)"
    else
        print_error "LocalStack: FAILED"
    fi
    
    # Test backend functions (if Go is available)
    if command -v go >/dev/null 2>&1; then
        cd backend
        if [ -f "bin/health-check" ]; then
            print_status "Testing health check..."
            make test-health
            print_status "Testing conversation handler..."
            make test-conversation
        else
            print_warning "Backend not built - run './dev.sh start' first"
        fi
        cd ..
    else
        print_warning "Go not available - skipping backend function tests"
    fi
}

# Main script logic
case "${1:-}" in
    "start")
        start_dev "$2"
        ;;
    "stop") 
        stop_dev
        ;;
    "restart")
        stop_dev
        start_dev "$2"
        ;;
    "test")
        test_dev
        ;;
    "status")
        if is_running; then
            print_success "Development environment is running"
            docker-compose -f backend/docker-compose.yml ps
        else
            print_warning "Development environment is stopped"
        fi
        ;;
    *)
        if is_running; then
            print_status "Development environment is running"
            echo "Usage: $0 {stop|restart|test|status}"
            echo "       $0 restart --with-ios"
        else
            print_status "Development environment is stopped"  
            echo "Usage: $0 {start|test|status}"
            echo "       $0 start --with-ios"
        fi
        ;;
esac
