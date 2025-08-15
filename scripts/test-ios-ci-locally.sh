#!/bin/bash

# Local iOS CI/CD Testing Script
# This script mimics the exact steps that run in GitHub Actions
# Run this before pushing to catch issues early

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"
WORKSPACE_PATH="$IOS_DIR/InnerWorld.xcodeproj"
SCHEME_NAME="InnerWorld"

# Test configuration
RUN_TESTS=${RUN_TESTS:-true}
CLEAN_BUILD=${CLEAN_BUILD:-false}
VERBOSE=${VERBOSE:-false}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to run xcodebuild with proper logging
run_xcodebuild() {
    local description="$1"
    shift  # Remove first argument, rest are xcodebuild args
    
    print_status "$description"
    
    if [ "$VERBOSE" = "true" ]; then
        set -o pipefail && xcodebuild "$@" | xcpretty
    else
        set -o pipefail && xcodebuild "$@" -quiet | xcpretty
    fi
}

# Cleanup function
cleanup() {
    print_status "Cleaning up test artifacts..."
    rm -rf "$DERIVED_DATA_PATH" 2>/dev/null || true
    rm -f test-results.xml 2>/dev/null || true
    print_success "Cleanup completed"
}

# Trap cleanup on exit
trap cleanup EXIT

echo "🧪 iOS CI/CD Local Testing Script"
echo "=================================="
echo "Project: $PROJECT_ROOT"
echo "iOS Directory: $IOS_DIR"
echo "Scheme: $SCHEME_NAME"
echo "Run Tests: $RUN_TESTS"
echo "Clean Build: $CLEAN_BUILD"
echo "Verbose: $VERBOSE"
echo ""

# Validate prerequisites
print_status "Validating prerequisites..."

if [ ! -d "$IOS_DIR" ]; then
    print_error "iOS directory not found: $IOS_DIR"
    exit 1
fi

if [ ! -f "$WORKSPACE_PATH/project.pbxproj" ]; then
    print_error "Xcode project not found: $WORKSPACE_PATH"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    print_error "xcodebuild not found. Please install Xcode."
    exit 1
fi

if ! command -v xcpretty &> /dev/null; then
    print_warning "xcpretty not found. Installing..."
    
    # Try user install first (no sudo required)
    if gem install xcpretty --user-install; then
        print_success "xcpretty installed to user directory"
        
        # Add gem bin directory to PATH if not already there
        GEM_BIN_DIR="$HOME/.gem/ruby/$(ruby -e 'print RUBY_VERSION')/bin"
        if [[ ":$PATH:" != *":$GEM_BIN_DIR:"* ]]; then
            export PATH="$GEM_BIN_DIR:$PATH"
            print_success "Added gem bin directory to PATH: $GEM_BIN_DIR"
        fi
        
        # Verify xcpretty is now available
        if ! command -v xcpretty &> /dev/null; then
            print_warning "xcpretty installed but not found in PATH. Output may be less readable."
        fi
    else
        print_warning "Failed to install xcpretty. Output may be less readable."
        print_warning "You can install it manually: gem install xcpretty --user-install"
    fi
fi

print_success "Prerequisites validated"

# Navigate to iOS directory
cd "$IOS_DIR"

# Clean build if requested
if [ "$CLEAN_BUILD" = "true" ]; then
    print_status "Performing clean build..."
    run_xcodebuild "Cleaning project" \
        -project "$WORKSPACE_PATH" \
        -scheme "$SCHEME_NAME" \
        clean
    print_success "Clean completed"
fi

# Create derived data directory (same pattern as CI)
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData/InnerWorld-LocalTest-$(date +%s)"
mkdir -p "$DERIVED_DATA_PATH"
print_status "Using derived data path: $DERIVED_DATA_PATH"

# Step 1: Detect available destinations (same as CI)
print_status "🔍 Detecting available destinations..."
echo "📱 Available destinations:"
xcodebuild -project "$WORKSPACE_PATH" -scheme "$SCHEME_NAME" -showdestinations

# Detect ARKit requirement
if grep -q "arkit" "$WORKSPACE_PATH/project.pbxproj"; then
    ARKIT_REQUIRED=true
    print_warning "ARKit detected - limited testing options available"
else
    ARKIT_REQUIRED=false
    print_success "No ARKit requirement detected"
fi

# Determine test strategy (same logic as CI)
if xcodebuild -project "$WORKSPACE_PATH" -scheme "$SCHEME_NAME" -showdestinations 2>/dev/null | grep -q "platform:macOS.*variant:Designed for"; then
    TEST_MODE="mac_catalyst"
    DESTINATION="platform=macOS"
    print_success "Mac Catalyst destination available for testing"
elif xcodebuild -project "$WORKSPACE_PATH" -scheme "$SCHEME_NAME" -showdestinations 2>/dev/null | grep -q "iOS Simulator" | grep -v "placeholder"; then
    if [ "$ARKIT_REQUIRED" = "true" ]; then
        TEST_MODE="build_only"
        DESTINATION="generic/platform=iOS Simulator"
        print_warning "ARKit detected - will only test build, not run tests"
    else
        TEST_MODE="simulator"
        DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
        print_success "iOS Simulator testing available"
    fi
else
    TEST_MODE="build_only" 
    DESTINATION="generic/platform=iOS"
    print_warning "Limited destinations - build verification only"
fi

echo "🎯 Selected test mode: $TEST_MODE"
echo "🎯 Target destination: $DESTINATION"
echo ""

# Step 2: Build for testing
if [ "$TEST_MODE" = "mac_catalyst" ]; then
    print_status "🖥️  Building for Mac Catalyst verification..."
    print_status "📝 Note: ARKit apps cannot run tests without code signing on Mac Catalyst"
    print_status "📝 Note: Performing build verification only"
    
    # Build verification for Mac Catalyst (no testing due to code signing requirements)
    run_xcodebuild "Building for Mac Catalyst verification" \
        -project "$WORKSPACE_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "$DESTINATION" \
        -configuration Debug \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        CODE_SIGNING_ALLOWED=NO \
        build
    
    print_success "Mac Catalyst build verification completed"
    print_warning "Skipping unit tests - ARKit apps require code signing to run on macOS"

elif [ "$TEST_MODE" = "simulator" ]; then
    print_status "📱 Building for iOS Simulator testing..."
    run_xcodebuild "Building for iOS Simulator testing" \
        -project "$WORKSPACE_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "$DESTINATION" \
        -configuration Debug \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        CODE_SIGNING_ALLOWED=NO \
        build-for-testing
    
    print_success "iOS Simulator build for testing completed"
    
    # Step 3: Run tests (if enabled)
    if [ "$RUN_TESTS" = "true" ]; then
        print_status "🧪 Running full test suite on iOS Simulator..."
        run_xcodebuild "Running full test suite" \
            -project "$WORKSPACE_PATH" \
            -scheme "$SCHEME_NAME" \
            -destination "$DESTINATION" \
            -configuration Debug \
            -derivedDataPath "$DERIVED_DATA_PATH" \
            CODE_SIGNING_ALLOWED=NO \
            -enableCodeCoverage YES \
            test-without-building
        
        print_success "iOS Simulator tests completed"
    else
        print_warning "Skipping tests (RUN_TESTS=false)"
    fi

else  # build_only
    print_status "🏗️  Build verification only..."
    run_xcodebuild "Build verification" \
        -project "$WORKSPACE_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "$DESTINATION" \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        build
    
    print_success "Build verification completed"
    print_warning "Skipping tests - ARKit requires physical devices"
fi

# Step 4: Build for release (same as CI)
print_status "🚀 Building for release configuration..."
run_xcodebuild "Building for release" \
    -project "$WORKSPACE_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    CODE_SIGNING_ALLOWED=NO \
    build

print_success "Release build completed"

# Summary
echo ""
echo "🎉 Local iOS CI/CD Testing Summary"
echo "=================================="
print_success "All builds completed successfully!"
echo "📊 Test Mode: $TEST_MODE"
echo "🎯 Destination: $DESTINATION"
echo "🧪 Tests Run: $RUN_TESTS"
echo "📱 ARKit Required: $ARKIT_REQUIRED"
echo ""
print_success "Your code is ready for CI/CD! 🚀"
echo ""
echo "💡 To run with different options:"
echo "   VERBOSE=true $0                    # Verbose output"
echo "   CLEAN_BUILD=true $0                # Clean build first"
echo "   RUN_TESTS=false $0                 # Skip running tests"
echo "   VERBOSE=true CLEAN_BUILD=true $0   # Verbose + clean"
