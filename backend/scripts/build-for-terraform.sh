#!/bin/bash

# Build Lambda functions for Terraform deployment
# This script builds the Go binaries and creates zip files for Terraform

set -e

echo "🔨 Building Lambda functions for Terraform deployment..."

# Create bin directory
mkdir -p bin

# Build health-check
echo "   Building health-check..."
cd /Users/darrenlund/Gauntlet/Capstone/InnerWorldApp/backend
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/bootstrap ./cmd/health-check/main.go
cd bin && zip health-check.zip bootstrap && rm bootstrap
cd ..

# Build conversation-handler  
echo "   Building conversation-handler..."
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/bootstrap ./cmd/conversation-handler/main.go
cd bin && zip conversation-handler.zip bootstrap && rm bootstrap
cd ..

echo "✅ Lambda deployment packages ready for Terraform:"
echo "   📦 backend/bin/health-check.zip"
echo "   📦 backend/bin/conversation-handler.zip"
echo ""
echo "🚀 Ready to deploy with Terraform:"
echo "   cd infrastructure/environments/dev"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
