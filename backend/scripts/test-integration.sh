#!/bin/bash
set -e

echo "=== InnerWorld Integration Tests ==="
echo "Testing AWS services via LocalStack (Docker required)"

# Check if we're in the backend directory
if [ ! -f "go.mod" ]; then
    echo "Error: Must run from backend directory"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running"
    echo "💡 Please start Docker and try again"
    exit 1
fi

# Check if LocalStack is running
if ! curl -f http://localhost:4566/_localstack/health >/dev/null 2>&1; then
    echo "❌ LocalStack is not running"
    echo "💡 Start with: docker-compose up -d"
    echo ""
    echo "Starting LocalStack now..."
    docker-compose up -d
    
    # Wait for LocalStack to be ready
    echo "⏳ Waiting for LocalStack to be ready..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f http://localhost:4566/_localstack/health >/dev/null 2>&1; then
            echo "✅ LocalStack is ready!"
            break
        fi
        sleep 2
        timeout=$((timeout-2))
    done
    
    if [ $timeout -le 0 ]; then
        echo "❌ Timeout waiting for LocalStack to start"
        exit 1
    fi
fi

# Build the integration test
echo ""
echo "Building integration test..."
go build -o bin/test-integration cmd/test-integration/main.go
echo "✅ Integration test built"

echo ""
echo "Running integration tests against LocalStack..."
./bin/test-integration

echo ""
echo "🎯 Integration tests validate:"
echo "  1. ✅ LocalStack AWS service emulation"
echo "  2. ✅ Real DynamoDB operations (create, put, get, query)" 
echo "  3. ✅ AWS SDK v2 integration"
echo "  4. ✅ Table schema and GSI functionality"
echo "  5. ✅ TTL attribute handling"
echo ""
echo "Ready for production AWS deployment!"
