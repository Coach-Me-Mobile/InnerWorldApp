#!/bin/bash

# InnerWorld Backend - Phase 1 Development Environment

set -e

echo "🚀 Starting InnerWorld Backend Phase 1 Development..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your API keys if you want to test real LLM integration"
    echo "   (Optional for Phase 1 - mock responses will be used otherwise)"
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p localstack

# Start Docker Compose services
echo "🐳 Starting Docker services..."
docker-compose up -d

echo "⏳ Waiting for services..."

# Wait for LocalStack
echo "   Waiting for LocalStack..."
for i in {1..30}; do
    if curl -f http://localhost:4566/_localstack/health >/dev/null 2>&1; then
        echo "✅ LocalStack is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ LocalStack failed to start"
        exit 1
    fi
    sleep 2
done



echo ""
echo "🎉 Phase 1 Development Environment is ready!"
echo ""
echo "📊 Available Services:"
echo "   • LocalStack (AWS): http://localhost:4566"
echo "   • Mock S3: Built into Go application"
echo ""
echo "🧪 Testing Commands:"
echo "   • Test Health Check: make test-health"
echo "   • Test Conversation: make test-conversation"
echo "   • Check Services: make test-services"
echo "   • Build Functions: make build"
echo ""
echo "🛑 To stop: make dev-stop"