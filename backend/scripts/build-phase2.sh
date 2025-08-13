#!/bin/bash
set -e

echo "=== Building InnerWorld Phase 2 Backend ==="

# Check if we're in the backend directory
if [ ! -f "go.mod" ]; then
    echo "Error: Must run from backend directory"
    exit 1
fi

# Create build output directory
mkdir -p bin

# Build Phase 2 Lambda functions
echo "Building Phase 2 Lambda functions..."

echo "  Building login-context-handler..."
GOOS=linux GOARCH=amd64 go build -o bin/login-context-handler cmd/login-context-handler/main.go

echo "  Building websocket-handler..."
GOOS=linux GOARCH=amd64 go build -o bin/websocket-handler cmd/websocket-handler/main.go

echo "  Building session-processor..."
GOOS=linux GOARCH=amd64 go build -o bin/session-processor cmd/session-processor/main.go

echo "  Building phase2 test..."
GOOS=linux GOARCH=amd64 go build -o bin/test-phase2 cmd/test-phase2/main.go

echo "  Building e2e conversation test..."
go build -o bin/test-e2e-conversation cmd/test-e2e-conversation/main.go

# Create ZIP files for Lambda deployment
echo "Creating deployment packages..."

cd bin

echo "  Packaging login-context-handler.zip..."
zip -q login-context-handler.zip login-context-handler

echo "  Packaging websocket-handler.zip..."
zip -q websocket-handler.zip websocket-handler

echo "  Packaging session-processor.zip..."
zip -q session-processor.zip session-processor

echo "  Packaging test-phase2.zip..."
zip -q test-phase2.zip test-phase2

echo "  Packaging test-e2e-conversation.zip..."
zip -q test-e2e-conversation.zip test-e2e-conversation

cd ..

echo "✅ Phase 2 build complete!"
echo ""
echo "Built Lambda functions:"
echo "  - bin/login-context-handler.zip"
echo "  - bin/websocket-handler.zip" 
echo "  - bin/session-processor.zip"
echo "  - bin/test-phase2.zip"
echo "  - bin/test-e2e-conversation.zip"
echo ""
echo "Next steps:"
echo "  1. Deploy infrastructure with Nataly's Terraform"
echo "  2. Upload Lambda functions to AWS"
echo "  3. Test with: ./scripts/test-phase2.sh"
