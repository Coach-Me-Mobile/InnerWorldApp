#!/bin/bash
# validate-ios-project.sh
# Custom validation script for iOS project structure and requirements

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation counters
ERRORS=0
WARNINGS=0

# Check if we're in the right directory
if [[ ! -f ".gitignore" ]] || [[ ! -f ".gitleaks.toml" ]]; then
    log_error "Must be run from project root directory"
    exit 1
fi

log_info "Validating iOS project structure for InnerWorldApp..."

# Check for required iOS project files
log_info "Checking for required iOS project files..."

# Look for Xcode project files
if [[ ! -f *.xcodeproj/project.pbxproj ]] && [[ ! -f *.xcworkspace/contents.xcworkspacedata ]]; then
    log_error "No Xcode project or workspace found"
    ((ERRORS++))
else
    log_info "Xcode project structure found"
fi

# Check for Info.plist
if ! find . -name "Info.plist" -not -path "./build/*" -not -path "./DerivedData/*" | grep -q .; then
    log_warn "No Info.plist found - ensure privacy usage descriptions are added when needed"
    ((WARNINGS++))
fi

# Check for required privacy documentation
log_info "Checking privacy and compliance documentation..."

PRIVACY_DOCS=(
    "documentation/privacy-policy.md"
    "documentation/terms-of-service.md"
    "documentation/crisis-resources.md"
)

for doc in "${PRIVACY_DOCS[@]}"; do
    if [[ ! -f "$doc" ]]; then
        log_warn "Missing privacy documentation: $doc"
        ((WARNINGS++))
    fi
done

# Check for AR/RealityKit requirements
log_info "Checking AR/RealityKit project setup..."

# Check for RealityKit usage in source files
if find . -name "*.swift" -exec grep -l "RealityKit\|ARKit" {} \; | grep -q .; then
    log_info "RealityKit/ARKit usage detected"
    
    # Check for AR privacy usage description reminder
    if ! grep -r "NSCameraUsageDescription" . 2>/dev/null; then
        log_warn "AR apps require NSCameraUsageDescription in Info.plist"
        ((WARNINGS++))
    fi
else
    log_warn "No RealityKit/ARKit usage found - expected for AR app"
    ((WARNINGS++))
fi

# Check for Neo4j/GraphRAG integration
log_info "Checking Neo4j/GraphRAG integration..."

if find . -name "*.swift" -exec grep -l "Neo4j\|GraphRAG\|neo4j" {} \; | grep -q .; then
    log_info "Neo4j/GraphRAG integration detected"
else
    log_warn "No Neo4j/GraphRAG integration found - expected for memory system"
    ((WARNINGS++))
fi

# Check for OpenAI/LLM integration
log_info "Checking OpenAI/LLM integration..."

if find . -name "*.swift" -exec grep -l "OpenAI\|openai\|LLM\|anthropic" {} \; | grep -q .; then
    log_info "LLM integration detected"
else
    log_warn "No LLM integration found - expected for persona AI"
    ((WARNINGS++))
fi

# Check for crisis resources implementation
log_info "Checking crisis resources implementation..."

CRISIS_PATTERNS=("988" "crisis" "hotline" "suicide" "emergency")
CRISIS_FOUND=false

for pattern in "${CRISIS_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        CRISIS_FOUND=true
        break
    fi
done

if $CRISIS_FOUND; then
    log_warn "Crisis-related content found in source code - ensure it's properly externalized"
    ((WARNINGS++))
fi

# Check for proper age gating (13+)
log_info "Checking age gating implementation..."

if find . -name "*.swift" -exec grep -l "age.*13\|thirteen\|teen" {} \; | grep -q .; then
    log_info "Age gating implementation detected"
else
    log_warn "No age gating found - required for 13+ app"
    ((WARNINGS++))
fi

# Check for session time limits (20 minutes)
log_info "Checking session time limits..."

if find . -name "*.swift" -exec grep -l "20.*minute\|1200.*second\|session.*limit" {} \; | grep -q .; then
    log_info "Session time limits detected"
else
    log_warn "No session time limits found - required for 20-minute daily cap"
    ((WARNINGS++))
fi

# Check for TestFlight configuration
log_info "Checking TestFlight/distribution setup..."

if [[ -d "fastlane" ]] || find . -name "*.mobileprovision" | grep -q .; then
    log_info "Distribution/TestFlight setup detected"
else
    log_warn "No TestFlight/distribution setup found"
    ((WARNINGS++))
fi

# Check for accessibility support
log_info "Checking accessibility implementation..."

ACCESSIBILITY_PATTERNS=("accessibilityLabel" "accessibilityHint" "VoiceOver" "DynamicType")
ACCESSIBILITY_FOUND=false

for pattern in "${ACCESSIBILITY_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        ACCESSIBILITY_FOUND=true
        break
    fi
done

if $ACCESSIBILITY_FOUND; then
    log_info "Accessibility implementation detected"
else
    log_warn "No accessibility implementation found - important for inclusive design"
    ((WARNINGS++))
fi

# Check for security best practices
log_info "Checking security implementation..."

SECURITY_PATTERNS=("Keychain" "SecureEnclave" "biometric" "FaceID" "TouchID")
SECURITY_FOUND=false

for pattern in "${SECURITY_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        SECURITY_FOUND=true
        break
    fi
done

if $SECURITY_FOUND; then
    log_info "Security implementation detected"
else
    log_warn "No security implementation found - important for user privacy"
    ((WARNINGS++))
fi

# Summary
log_info "Validation complete!"
log_info "Errors: $ERRORS"
log_info "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    log_error "Validation failed with $ERRORS errors"
    exit 1
elif [[ $WARNINGS -gt 5 ]]; then
    log_warn "Many warnings found ($WARNINGS) - consider addressing them"
    exit 0
else
    log_info "Validation passed!"
    exit 0
fi
