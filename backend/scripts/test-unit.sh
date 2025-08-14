#!/bin/bash
set -e

echo "=== InnerWorld Unit Tests ==="
echo "Testing individual components in isolation"

# Check if we're in the backend directory
if [ ! -f "go.mod" ]; then
    echo "Error: Must run from backend directory"
    exit 1
fi

echo ""
echo "Running Go unit tests..."
go test ./internal/... -v

echo ""
echo "✅ Unit tests complete!"
echo ""
echo "Unit tests validate:"
echo "  • Configuration loading and validation"
echo "  • OpenAI embeddings client"
echo "  • OpenRouter LLM client"  
echo "  • Conversation type validation"
echo "  • Core component functionality"
echo ""
echo "For comprehensive testing, run:"
echo "  • ./scripts/test-e2e-conversation.sh (full workflow)"
echo "  • ./scripts/test-integration.sh (AWS services)"
