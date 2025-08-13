#!/bin/bash

# InnerWorld SAM Local Testing Script

echo "🧪 Testing InnerWorld Lambda Functions with SAM Local..."
echo "========================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    print_error "SAM CLI not found. Install with: brew install aws-sam-cli"
    exit 1
fi

print_status "SAM CLI found: $(sam --version)"

# Check if Lambda functions are built
if [ ! -f "bin/conversation-handler-linux" ] || [ ! -f "bin/health-check-linux" ]; then
    print_warning "Lambda functions not built for Linux. Building now..."
    make build-lambda
fi

# Load environment variables if .env exists
if [ -f ".env" ]; then
    print_status "Loading environment variables from .env..."
    export $(cat .env | grep -v '#' | xargs)
fi

# Create sam-events directory if it doesn't exist
mkdir -p sam-events

echo ""
print_status "Testing Lambda functions with SAM local..."
echo ""

# Test 1: Health Check Function
echo "📋 Test 1: Health Check Function"
echo "================================"
START_TIME=$(date +%s%N)

if sam local invoke HealthCheck --event sam-events/health-event.json --region us-west-2; then
    END_TIME=$(date +%s%N)
    ELAPSED=$(( (END_TIME - START_TIME) / 1000000 ))
    print_success "Health check completed in ${ELAPSED}ms"
else
    print_error "Health check failed"
    exit 1
fi

echo ""

# Test 2: Conversation Handler Function
echo "💬 Test 2: Conversation Handler Function"
echo "========================================"
START_TIME=$(date +%s%N)

if sam local invoke ConversationHandler --event sam-events/conversation-event.json --region us-west-2; then
    END_TIME=$(date +%s%N)
    ELAPSED=$(( (END_TIME - START_TIME) / 1000000 ))
    print_success "Conversation handler completed in ${ELAPSED}ms"
else
    print_error "Conversation handler failed"
    exit 1
fi

echo ""

# Test 3: Direct Invocation (without API Gateway wrapper)
echo "🎯 Test 3: Direct Conversation Invocation"
echo "========================================="
START_TIME=$(date +%s%N)

if sam local invoke ConversationHandler --event sam-events/conversation-direct.json --region us-west-2; then
    END_TIME=$(date +%s%N)
    ELAPSED=$(( (END_TIME - START_TIME) / 1000000 ))
    print_success "Direct invocation completed in ${ELAPSED}ms"
else
    print_error "Direct invocation failed"
    exit 1
fi

echo ""
print_success "🎉 All SAM local tests passed!"
echo ""
print_status "To start local API Gateway for manual testing:"
echo "   make test-sam-api"
echo ""
print_status "To test individual functions:"
echo "   make test-sam-conversation"
echo "   make test-sam-health"
