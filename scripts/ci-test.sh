#!/bin/bash

# CI/CD Testing Wrapper Script
# Provides easy testing commands for different scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_help() {
    echo "🧪 CI/CD Testing Wrapper"
    echo "========================"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  ios              Run iOS CI/CD pipeline locally"
    echo "  ios-quick        Run iOS build only (no tests)"
    echo "  ios-clean        Run iOS with clean build"
    echo "  ios-verbose      Run iOS with verbose output"
    echo "  github-actions   Test GitHub Actions workflow locally (requires act)"
    echo "  setup-act        Install and setup 'act' for local GitHub Actions testing"
    echo "  validate         Validate project structure and requirements"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ios                    # Full iOS testing"
    echo "  $0 ios-quick              # Quick build verification"
    echo "  $0 setup-act              # Setup local GitHub Actions testing"
    echo "  $0 github-actions         # Test GitHub Actions locally"
}

setup_act() {
    echo -e "${BLUE}Setting up 'act' for local GitHub Actions testing...${NC}"
    
    if command -v act &> /dev/null; then
        echo -e "${GREEN}✅ 'act' is already installed${NC}"
    else
        echo "Installing 'act'..."
        if command -v brew &> /dev/null; then
            brew install act
        else
            echo -e "${YELLOW}⚠️  Homebrew not found. Please install 'act' manually:${NC}"
            echo "   curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
            exit 1
        fi
    fi
    
    # Create act configuration
    cat > .actrc << EOF
# Act configuration for local GitHub Actions testing
--platform ubuntu-latest=catthehacker/ubuntu:act-latest
--platform ubuntu-22.04=catthehacker/ubuntu:act-22.04
--platform macos-latest=catthehacker/ubuntu:act-latest
--platform macos-14=catthehacker/ubuntu:act-latest
-s GITHUB_TOKEN=placeholder
EOF

    echo -e "${GREEN}✅ Act setup completed${NC}"
    echo ""
    echo -e "${YELLOW}Note: iOS builds require macOS, so 'act' will have limitations.${NC}"
    echo -e "${YELLOW}Use 'act --list' to see available workflows.${NC}"
}

run_github_actions() {
    echo -e "${BLUE}Testing GitHub Actions workflow locally...${NC}"
    
    if ! command -v act &> /dev/null; then
        echo -e "${YELLOW}⚠️  'act' not found. Running setup first...${NC}"
        setup_act
    fi
    
    echo "Available workflows:"
    act --list
    
    echo ""
    echo -e "${YELLOW}Note: iOS workflows may not work fully in act due to macOS requirement.${NC}"
    echo "Attempting to run workflow validation..."
    
    # Try to run a dry-run
    act --dry-run || {
        echo -e "${YELLOW}⚠️  Act dry-run failed. This is expected for iOS workflows.${NC}"
        echo "Use the iOS-specific local testing instead: $0 ios"
    }
}

validate_project() {
    echo -e "${BLUE}Validating project structure and requirements...${NC}"
    
    # Check iOS project
    if [ -d "ios" ] && [ -f "ios/InnerWorld.xcodeproj/project.pbxproj" ]; then
        echo -e "${GREEN}✅ iOS project found${NC}"
    else
        echo -e "${YELLOW}⚠️  iOS project not found or incomplete${NC}"
    fi
    
    # Check backend
    if [ -d "backend" ] && [ -f "backend/go.mod" ]; then
        echo -e "${GREEN}✅ Backend project found${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend project not found or incomplete${NC}"
    fi
    
    # Check CI/CD
    if [ -f ".github/workflows/ios-cicd.yml" ]; then
        echo -e "${GREEN}✅ iOS CI/CD workflow found${NC}"
    else
        echo -e "${YELLOW}⚠️  iOS CI/CD workflow not found${NC}"
    fi
    
    # Check prerequisites
    echo ""
    echo "Prerequisites check:"
    
    if command -v xcodebuild &> /dev/null; then
        echo -e "${GREEN}✅ xcodebuild available${NC}"
        xcodebuild -version | head -1
    else
        echo -e "${YELLOW}⚠️  xcodebuild not found${NC}"
    fi
    
    if command -v xcpretty &> /dev/null; then
        echo -e "${GREEN}✅ xcpretty available${NC}"
    else
        echo -e "${YELLOW}⚠️  xcpretty not found (will install when needed)${NC}"
    fi
    
    if command -v go &> /dev/null; then
        echo -e "${GREEN}✅ Go available${NC}"
        go version
    else
        echo -e "${YELLOW}⚠️  Go not found${NC}"
    fi
}

case "${1:-help}" in
    "ios")
        echo -e "${BLUE}Running full iOS CI/CD testing...${NC}"
        "$SCRIPT_DIR/test-ios-ci-locally.sh"
        ;;
    "ios-quick")
        echo -e "${BLUE}Running quick iOS build verification...${NC}"
        RUN_TESTS=false "$SCRIPT_DIR/test-ios-ci-locally.sh"
        ;;
    "ios-clean")
        echo -e "${BLUE}Running iOS testing with clean build...${NC}"
        CLEAN_BUILD=true "$SCRIPT_DIR/test-ios-ci-locally.sh"
        ;;
    "ios-verbose")
        echo -e "${BLUE}Running iOS testing with verbose output...${NC}"
        VERBOSE=true "$SCRIPT_DIR/test-ios-ci-locally.sh"
        ;;
    "setup-act")
        setup_act
        ;;
    "github-actions")
        run_github_actions
        ;;
    "validate")
        validate_project
        ;;
    "help"|*)
        print_help
        ;;
esac
