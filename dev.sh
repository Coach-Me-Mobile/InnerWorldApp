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

# Load environment
load_env() {
    if [ ! -f ".env" ]; then
        print_warning "No .env found, creating from template..."
        cp .env.example .env
        print_status "Edit .env to add API keys (optional)"
    fi
    export $(cat .env | grep -v '#' | grep -v '^$' | xargs)
}

# Check if services are running
is_running() {
    docker-compose -f backend/docker-compose.yml ps -q | grep -q . 2>/dev/null
}

# Start development environment
start_dev() {
    print_status "Starting InnerWorld development environment..."
    
    load_env
    
    # Check Docker
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker not running. Please start Docker Desktop."
        exit 1
    fi
    
    # Start LocalStack (only service we need)
    print_status "Starting LocalStack..."
    cd backend && docker-compose up -d && cd ..
    
    # Wait for LocalStack
    print_status "Waiting for LocalStack..."
    for i in {1..30}; do
        if curl -f http://localhost:4566/_localstack/health >/dev/null 2>&1; then
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "LocalStack failed to start"
            exit 1
        fi
        sleep 2
    done
    
    # Build backend functions
    print_status "Building backend functions..."
    cd backend && make build && cd ..
    
    print_success "Development environment ready!"
    echo ""
    echo "🌐 Services:"
    echo "   • Backend API: http://localhost:3000 (use 'make test-sam-api' in backend/)"
    echo "   • Health Check: http://localhost:3000/health"  
    echo "   • LocalStack: http://localhost:4566"
    echo ""
    echo "🧪 Testing:"
    echo "   • ./dev.sh test"
    echo ""
    echo "🛑 Stop:"
    echo "   • ./dev.sh stop"
}

# Stop development environment  
stop_dev() {
    print_status "Stopping InnerWorld development environment..."
    cd backend && docker-compose down && cd ..
    print_success "Development environment stopped"
}

# Test services
test_dev() {
    print_status "Testing development services..."
    
    # Test LocalStack
    if curl -f http://localhost:4566/_localstack/health >/dev/null 2>&1; then
        print_success "LocalStack: OK"
    else
        print_error "LocalStack: FAILED"
    fi
    
    # Test backend functions
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
}

# Main script logic
case "${1:-}" in
    "start")
        start_dev
        ;;
    "stop") 
        stop_dev
        ;;
    "restart")
        stop_dev
        start_dev
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
        else
            print_status "Development environment is stopped"  
            echo "Usage: $0 {start|test|status}"
        fi
        ;;
esac
