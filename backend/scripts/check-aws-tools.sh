#!/bin/bash

# AWS Tools Installation Check Script

echo "🔧 Checking AWS Development Tools..."
echo "==================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if command exists
check_command() {
    local cmd=$1
    local name=$2
    local install_cmd=$3
    
    if command -v $cmd &> /dev/null; then
        echo -e "✅ ${GREEN}$name${NC} found: $($cmd --version 2>&1 | head -n1)"
        return 0
    else
        echo -e "❌ ${RED}$name${NC} not found"
        if [ ! -z "$install_cmd" ]; then
            echo -e "   Install with: ${YELLOW}$install_cmd${NC}"
        fi
        return 1
    fi
}

echo "📋 Required Tools:"
echo "-----------------"

# Check Go
check_command "go" "Go" "Visit https://golang.org/doc/install"

# Check AWS CLI
check_command "aws" "AWS CLI" "brew install awscli"

# Check SAM CLI
check_command "sam" "SAM CLI" "brew install aws-sam-cli"

# Check Docker
check_command "docker" "Docker" "Visit https://docs.docker.com/get-docker/"

echo ""
echo "📋 Optional Tools:"
echo "-----------------"

# Check jq
check_command "jq" "jq (JSON processor)" "brew install jq"

# Check curl
check_command "curl" "curl" "Usually pre-installed"

echo ""
echo "🎯 Testing Commands:"
echo "==================="
echo "After installing missing tools, try these commands:"
echo ""
echo "🏗️  Build Lambda functions:"
echo "   make build-lambda"
echo ""
echo "🧪 Test with SAM local:"
echo "   make test-sam"
echo ""
echo "🚀 Start local API Gateway:"
echo "   make test-sam-api"
echo ""
