#!/bin/bash

# InnerWorld Health Check Test Script

echo "🏥 Testing InnerWorld Health Check..."
echo "====================================="
echo ""

echo "🔨 Building health check test..."
if ! go build -o /tmp/health-test ./cmd/test-health/main.go; then
    echo "❌ Failed to build health check test"
    exit 1
fi

echo "🚀 Running health check..."

# Set environment variables for testing
export ENVIRONMENT=development
export DEBUG=true

# Check if API keys are available
if [ -f ".env" ]; then
    echo "📝 Loading environment variables from .env..."
    export $(cat .env | grep -v '#' | xargs)
fi

echo ""

START_TIME=$(date +%s%N)

# Run the health check test
RESPONSE=$(/tmp/health-test 2>/dev/null)
EXIT_CODE=$?

END_TIME=$(date +%s%N)
ELAPSED=$(( (END_TIME - START_TIME) / 1000000 )) # Convert to milliseconds

# Cleanup
rm -f /tmp/health-test

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Health check failed with exit code $EXIT_CODE"
    exit 1
fi

echo "✅ Health check completed in ${ELAPSED}ms"
echo ""

# Parse and display results
OVERALL_STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null || echo "unknown")
TIMESTAMP=$(echo "$RESPONSE" | jq -r '.timestamp' 2>/dev/null || echo "unknown")
VERSION=$(echo "$RESPONSE" | jq -r '.version' 2>/dev/null || echo "unknown")

echo "📊 Health Check Results:"
echo "======================="
echo "Overall Status: $OVERALL_STATUS"
echo "Version: $VERSION"
echo "Timestamp: $TIMESTAMP"
echo ""

# Check individual services
echo "🔧 Service Health:"
NEPTUNE_STATUS=$(echo "$RESPONSE" | jq -r '.services.neptune.status' 2>/dev/null || echo "unknown")
NEPTUNE_TIME=$(echo "$RESPONSE" | jq -r '.services.neptune.responseTime' 2>/dev/null || echo "unknown")
OPENROUTER_STATUS=$(echo "$RESPONSE" | jq -r '.services.openrouter.status' 2>/dev/null || echo "unknown")
OPENAI_STATUS=$(echo "$RESPONSE" | jq -r '.services.openai.status' 2>/dev/null || echo "unknown")

echo "   • Neptune (Mock): $NEPTUNE_STATUS ($NEPTUNE_TIME)"
echo "   • OpenRouter API: $OPENROUTER_STATUS (cost optimization)"
echo "   • OpenAI API: $OPENAI_STATUS (cost optimization)"
echo ""

# Show debug info if available
DEBUG_INFO=$(echo "$RESPONSE" | jq -r '.debug' 2>/dev/null)
if [ "$DEBUG_INFO" != "null" ] && [ "$DEBUG_INFO" != "" ]; then
    echo "🔍 Debug Information:"
    ENVIRONMENT=$(echo "$RESPONSE" | jq -r '.debug.environment' 2>/dev/null || echo "unknown")
    RESPONSE_TIME_MS=$(echo "$RESPONSE" | jq -r '.debug.responseTimeMs' 2>/dev/null || echo "unknown")
    echo "   • Environment: $ENVIRONMENT"
    echo "   • Internal Response Time: ${RESPONSE_TIME_MS}ms"
    echo ""
fi

# Overall assessment
case $OVERALL_STATUS in
    "healthy")
        echo "🎉 All systems operational!"
        ;;
    "degraded")
        echo "⚠️  System operational but some services are slow"
        ;;
    "unhealthy")
        echo "❌ System issues detected - check service logs"
        exit 1
        ;;
    *)
        echo "❓ Unknown health status: $OVERALL_STATUS"
        ;;
esac

echo ""
echo "📋 Full Response (JSON):"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
