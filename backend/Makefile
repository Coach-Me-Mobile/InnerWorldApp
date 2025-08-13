# InnerWorld Backend - Phase 1 Development Makefile

.PHONY: help dev-start dev-stop build build-lambda test test-sam clean deps setup check-sam-cli

# Default target
help: ## Show this help message
	@echo "InnerWorld Backend - Phase 1"
	@echo "============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development Environment
dev-start: ## Start development environment
	@chmod +x scripts/dev-start.sh
	@./scripts/dev-start.sh

dev-stop: ## Stop development environment
	@chmod +x scripts/dev-stop.sh
	@./scripts/dev-stop.sh

dev-restart: dev-stop dev-start ## Restart development environment

# Dependencies and Setup
deps: ## Install Go dependencies
	@echo "📦 Installing Go dependencies..."
	@go mod download
	@go mod tidy

check-sam-cli: ## Check if SAM CLI is installed
	@echo "🔍 Checking SAM CLI installation..."
	@if ! command -v sam > /dev/null; then \
		echo "❌ SAM CLI not found. Install with:"; \
		echo "   brew install aws-sam-cli"; \
		echo "   or visit: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"; \
		exit 1; \
	else \
		echo "✅ SAM CLI found: $$(sam --version)"; \
	fi

setup: ## Initial project setup
	@echo "🛠️  Setting up InnerWorld Backend Phase 1..."
	@mkdir -p localstack
	@mkdir -p sam-events
	@cp env.example .env || true
	@make deps
	@make check-sam-cli || echo "⚠️  SAM CLI not installed - Lambda testing will be limited"
	@echo "✅ Setup complete! Edit .env file with your API keys, then run 'make dev-start'"

# Building
build: ## Build Lambda functions for local development
	@echo "🔨 Building Lambda functions for local development..."
	@mkdir -p bin
	@go build -o bin/health-check ./cmd/health-check/main.go
	@go build -o bin/conversation-handler ./cmd/conversation-handler/main.go
	@echo "✅ Local build complete"

build-lambda: ## Build Lambda functions for AWS deployment (Linux)
	@echo "🔨 Building Lambda functions for AWS deployment..."
	@mkdir -p bin
	@echo "   Building health-check for Linux..."
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/bootstrap ./cmd/health-check/main.go
	@cd bin && zip health-check.zip bootstrap && rm bootstrap
	@echo "   Building conversation-handler for Linux..."
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/bootstrap ./cmd/conversation-handler/main.go
	@cd bin && zip conversation-handler.zip bootstrap && rm bootstrap
	@echo "✅ Lambda deployment packages ready:"
	@echo "   📦 bin/health-check.zip"
	@echo "   📦 bin/conversation-handler.zip"

# Testing
test: ## Run basic Go tests
	@echo "🧪 Running Go tests..."
	@go test -v ./...

test-conversation: ## Test conversation handler locally
	@chmod +x scripts/test-conversation.sh
	@./scripts/test-conversation.sh

test-health: ## Test health check handler locally
	@chmod +x scripts/test-health.sh
	@./scripts/test-health.sh

test-sam: check-sam-cli build-lambda ## Test Lambda functions with SAM local
	@echo "🧪 Testing Lambda functions with SAM local..."
	@chmod +x scripts/test-sam-local.sh
	@./scripts/test-sam-local.sh

test-sam-conversation: check-sam-cli build-lambda ## Test conversation handler with SAM local
	@echo "🧪 Testing conversation handler with SAM local..."
	@sam local invoke ConversationHandler --event sam-events/conversation-event.json

test-sam-health: check-sam-cli build-lambda ## Test health check with SAM local
	@echo "🧪 Testing health check with SAM local..."
	@sam local invoke HealthCheck --event sam-events/health-event.json

test-sam-api: check-sam-cli build-lambda ## Start SAM local API Gateway
	@echo "🚀 Starting SAM local API Gateway on http://localhost:3000..."
	@sam local start-api

test-services: ## Test development services
	@echo "🔍 Testing services..."
	@echo "LocalStack:" && curl -f http://localhost:4566/_localstack/health || echo "❌ LocalStack not ready"

# Utilities
clean: ## Clean build artifacts
	@echo "🗑️  Cleaning up..."
	@rm -rf bin/
	@rm -rf .aws-sam/
	@docker-compose down || true

logs: ## Show development logs
	@docker-compose logs -f

status: ## Show service status
	@echo "📊 Development Status:"
	@echo "====================="
	@docker-compose ps

# Quick commands
start: dev-start ## Alias for dev-start
stop: dev-stop ## Alias for dev-stop
lambda: build-lambda ## Alias for build-lambda
sam: test-sam ## Alias for test-sam