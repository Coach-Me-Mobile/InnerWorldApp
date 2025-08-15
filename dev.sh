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
    echo ""
    print_status "Shutting down development environment..."
    
    # Stop docker containers
    if docker-compose -f backend/docker-compose.yml ps -q | grep -q .; then
        print_status "Stopping Docker containers..."
        docker-compose -f backend/docker-compose.yml down
    fi
    
    # Stop iOS simulator if running
    if command -v xcrun >/dev/null 2>&1; then
        local running_devices=$(xcrun simctl list devices booted | grep "iPhone" | wc -l)
        if [ "$running_devices" -gt 0 ]; then
            print_status "Shutting down iOS simulators..."
            xcrun simctl shutdown booted >/dev/null 2>&1 || true
        fi
    fi
    
    print_success "Development environment stopped"
    exit 0
}

# Set up signal traps for cleanup
trap cleanup SIGINT SIGTERM

# Load environment
load_env() {
    if [ ! -f ".env" ]; then
        print_warning "No .env found, creating from template..."
        cp .env.example .env
        print_status "Edit .env to add API keys (optional - using mocks for now)"
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
    
    # Check Go (optional for building Lambda functions)
    if ! command -v go >/dev/null 2>&1; then
        print_warning "Go not found - Lambda functions won't be built locally"
        print_status "Install Go: brew install go (optional)"
        return 1
    fi
    
    return 0
}

# Start iOS simulator and app
start_ios() {
    if ! command -v xcrun >/dev/null 2>&1; then
        print_warning "Xcode tools not available - skipping iOS simulator"
        return 1
    fi
    
    print_status "Starting iOS Simulator..."
    
    # Get the first available iPhone simulator
    local device_id=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
    
    if [ -z "$device_id" ]; then
        print_warning "No iPhone simulators available"
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
    cd ios
    
    # Clean previous builds for reliability
    print_status "Cleaning previous builds..."
    xcodebuild -project InnerWorld.xcodeproj -scheme InnerWorld -destination "id=$device_id" clean >/dev/null 2>&1 || true
    
    # Build with less verbose output for cleaner logs
    print_status "Compiling iOS app..."
    if xcodebuild -project InnerWorld.xcodeproj -scheme InnerWorld -destination "id=$device_id" -configuration Debug -derivedDataPath build -allowProvisioningUpdates >/dev/null 2>&1; then
        print_success "iOS build completed successfully"
        
        # Find the built app
        local app_path=$(find build -name "InnerWorld.app" -path "*/Debug-iphonesimulator/*" | head -1)
        if [ -n "$app_path" ] && [ -d "$app_path" ]; then
            print_status "Installing app on simulator..."
            xcrun simctl install "$device_id" "$app_path"
            print_success "InnerWorld app installed on simulator"
            
            # Launch the app
            print_status "Launching InnerWorld app..."
            if xcrun simctl launch "$device_id" com.thoughtmanifold.InnerWorld >/dev/null 2>&1; then
                print_success "InnerWorld app launched successfully"
                cd ..
                return 0
            else
                print_warning "App installed but launch failed"
            fi
        else
            print_warning "Build succeeded but app not found at expected location"
        fi
    else
        print_warning "Failed to build iOS app"
    fi
    cd ..
    return 1
}

# Main development environment function
main() {
    print_status "🚀 Starting InnerWorld Development Environment"
    echo ""
    
    # Load environment
    load_env
    
    # Check prerequisites
    if check_prerequisites; then
        GO_AVAILABLE=true
        print_success "Go found - Lambda functions will be built"
    else
        GO_AVAILABLE=false
    fi
    
    # Check for --with-ios flag
    START_IOS=false
    for arg in "$@"; do
        if [ "$arg" = "--with-ios" ]; then
            START_IOS=true
            break
        fi
    done
    
    # Start LocalStack
    print_status "Starting LocalStack (AWS services)..."
    cd backend
    docker-compose up -d
    cd ..
    
    # Wait for LocalStack to be ready
    print_status "Waiting for LocalStack to be ready..."
    for i in {1..30}; do
        if docker inspect innerworld-localstack --format='{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
            print_success "LocalStack is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "LocalStack failed to start"
            exit 1
        fi
        sleep 2
    done
    
    # Build backend functions if Go is available
    if [ "$GO_AVAILABLE" = true ]; then
        print_status "Building Lambda functions..."
        cd backend && make build >/dev/null 2>&1 && cd ..
        print_success "Lambda functions built"
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
    
    # Show running services
    echo ""
    print_success "🌟 Development environment is ready!"
    echo ""
    echo "🌐 Services running:"
    if [ "$GO_AVAILABLE" = true ]; then
        echo "   • Backend API: http://localhost:3000"
        echo "   • Health Check: http://localhost:3000/health"  
    fi
    echo "   • LocalStack: http://localhost:4566"
    if [ "$IOS_RUNNING" = true ]; then
        echo "   • iOS App: Running in Simulator"
    fi
    echo ""
    print_status "Press Ctrl+C to stop all services"
    echo ""
    
    # Follow logs from LocalStack and show a continuous stream
    print_status "📋 Streaming logs (press Ctrl+C to stop)..."
    echo ""
    
    # Stream logs from docker containers
    docker-compose -f backend/docker-compose.yml logs -f
}

# Run the main function with all arguments
main "$@"
