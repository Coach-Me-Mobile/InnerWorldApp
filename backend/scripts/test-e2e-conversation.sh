#!/bin/bash
set -e

echo "=== InnerWorld End-to-End Conversation Test ==="
echo "Testing complete WebSocket conversation pipeline..."

# Check if we're in the backend directory
if [ ! -f "go.mod" ]; then
    echo "Error: Must run from backend directory"
    exit 1
fi

# Build the test if binary doesn't exist
if [ ! -f "bin/test-e2e-conversation" ]; then
    echo "Building end-to-end conversation test..."
    go build -o bin/test-e2e-conversation cmd/test-e2e-conversation/main.go
    echo "✅ Test built successfully"
    echo ""
fi

# Run the end-to-end test
./bin/test-e2e-conversation

echo ""
echo "🎯 This test demonstrates:"
echo "  1. ✅ Setup works (all components initialized)"
echo "  2. ✅ WebSocket connect loads mock Neptune data"
echo "  3. ✅ Bidirectional safety checks on all messages"
echo "  4. ✅ System prompt context injection with persona"
echo "  5. ✅ DynamoDB storage with 24-hour TTL verification" 
echo "  6. ✅ WebSocket disconnect with resource cleanup"
echo ""
echo "Ready for AWS infrastructure deployment!"
