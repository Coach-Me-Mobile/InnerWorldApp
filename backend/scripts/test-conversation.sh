#!/bin/bash

# InnerWorld Conversation Handler Test Script

echo "🧪 Testing InnerWorld Conversation Handler..."
echo "============================================="
echo ""

# Test data
TEST_MESSAGE="Hello! I'm feeling a bit nervous about starting something new."
TEST_USER="test-user-123"

echo "📤 Sending test message: \"$TEST_MESSAGE\""
echo "👤 From user: $TEST_USER"
echo ""

# Create test JSON payload
TEST_PAYLOAD=$(cat <<EOF
{
  "message": "$TEST_MESSAGE",
  "userId": "$TEST_USER"
}
EOF
)

echo "🔨 Building conversation test..."
if ! go build -o /tmp/conversation-test ./cmd/test-conversation/main.go; then
    echo "❌ Failed to build conversation test"
    exit 1
fi

echo "🚀 Starting conversation handler..."

# Set environment variables for testing
export ENVIRONMENT=development
export DEBUG=true

# Check if API keys are available
if [ -f ".env" ]; then
    echo "📝 Loading environment variables from .env..."
    export $(cat .env | grep -v '#' | xargs)
fi

# Test the conversation handler with direct invocation
echo "💬 Testing conversation..."
echo ""

START_TIME=$(date +%s%N)

# Invoke the Lambda function directly with our test payload
RESPONSE=$(echo "$TEST_PAYLOAD" | /tmp/conversation-test 2>/dev/null)
EXIT_CODE=$?

END_TIME=$(date +%s%N)
ELAPSED=$(( (END_TIME - START_TIME) / 1000000 )) # Convert to milliseconds

# Cleanup
rm -f /tmp/conversation-test

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Conversation handler failed with exit code $EXIT_CODE"
    exit 1
fi

echo "✅ Response received in ${ELAPSED}ms"
echo ""
echo "📋 Full Response:"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
echo ""

# Extract and display the AI response content
CONTENT=$(echo "$RESPONSE" | jq -r '.content' 2>/dev/null || echo "Could not parse content")
MESSAGE_ID=$(echo "$RESPONSE" | jq -r '.messageId' 2>/dev/null || echo "unknown")

echo "💬 AI Response:"
echo "   \"$CONTENT\""
echo ""
echo "🆔 Message ID: $MESSAGE_ID"
echo ""

# Check if it was a mock response or real OpenRouter
if echo "$CONTENT" | grep -q "mock response"; then
    echo "ℹ️  Used mock response (no OpenRouter API key configured)"
    echo "   To test real OpenRouter integration, add OPENROUTER_API_KEY to your .env file"
else
    echo "🌐 Used real OpenRouter API integration"
    echo "   ✅ LLM conversation working properly"
fi

echo ""
echo "🎉 Conversation test completed successfully!"
