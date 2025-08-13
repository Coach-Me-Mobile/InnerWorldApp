#!/bin/bash

# InnerWorld Backend - Development Environment Shutdown Script

set -e

echo "🛑 Stopping InnerWorld Backend Development Environment..."

# Stop Docker Compose services
echo "🐳 Stopping Docker services..."
docker-compose down

# Optional: Remove volumes (uncomment to clean data on each restart)
# echo "🗑️  Removing development data volumes..."
# docker-compose down -v

echo "✅ Development environment stopped"
echo ""
echo "💡 Tips:"
echo "   • To clean all data: docker-compose down -v"
echo "   • To view remaining containers: docker ps -a"
echo "   • To restart: make dev-start"
