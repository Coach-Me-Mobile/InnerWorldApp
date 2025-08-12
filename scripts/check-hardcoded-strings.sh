#!/bin/bash
# check-hardcoded-strings.sh
# Detect hardcoded strings that should be externalized in iOS app

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

log_info "Checking for hardcoded strings in Swift files..."

# Check for hardcoded user-facing strings (should be localized)
log_info "Checking for hardcoded user-facing strings..."

USER_FACING_PATTERNS=(
    '"[A-Z][a-z].*[.!?]"'     # Sentences starting with capital
    '".*\s+.*\s+.*"'          # Multi-word strings
    '"(Hello|Welcome|Error|Success|Please|Thank|Sorry|Yes|No|OK|Cancel)"'  # Common UI strings
)

for pattern in "${USER_FACING_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock" | head -10; then
        log_warn "Found potential hardcoded user-facing strings (should be localized)"
        ((WARNINGS++))
    fi
done

# Check for hardcoded URLs and endpoints
log_info "Checking for hardcoded URLs and API endpoints..."

URL_PATTERNS=(
    '"https?://[^"]*"'
    '".*\.com[^"]*"'
    '".*\.org[^"]*"'
    '".*\.net[^"]*"'
)

for pattern in "${URL_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "example\.com\|localhost\|127\.0\.0\.1"); then
        echo "$matches" | head -5
        log_warn "Found hardcoded URLs (should use environment variables)"
        ((WARNINGS++))
    fi
done

# Check for hardcoded API keys or tokens
log_info "Checking for potential hardcoded API keys..."

API_KEY_PATTERNS=(
    '"[sS][kK]-[a-zA-Z0-9]{48}"'        # OpenAI API keys
    '"[sS][kK]-[oO][rR]-[a-zA-Z0-9-_]{43}"'  # OpenRouter API keys
    '"[aA][iI][zZ][aA][a-zA-Z0-9]{35}"'      # Google API keys
    '"[a-fA-F0-9]{32,64}"'              # Generic hex keys
    '"Bearer\s+[a-zA-Z0-9+/=]{20,}"'    # Bearer tokens
)

for pattern in "${API_KEY_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock\|example\|placeholder"); then
        echo "$matches"
        log_error "Found potential hardcoded API keys!"
        ((ERRORS++))
    fi
done

# Check for hardcoded database credentials
log_info "Checking for hardcoded database credentials..."

DB_PATTERNS=(
    '"neo4j://[^"]*"'
    '"bolt://[^"]*"'
    '"mongodb://[^"]*"'
    '"postgres://[^"]*"'
    '"mysql://[^"]*"'
    '"password":\s*"[^"]{6,}"'
    '"username":\s*"[^"]{3,}"'
)

for pattern in "${DB_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock\|example\|placeholder"); then
        echo "$matches"
        log_error "Found potential hardcoded database credentials!"
        ((ERRORS++))
    fi
done

# Check for hardcoded crisis resources
log_info "Checking for hardcoded crisis resources..."

CRISIS_PATTERNS=(
    '".*988.*"'
    '".*1-800-[0-9-]*"'
    '".*suicide.*"'
    '".*crisis.*"'
    '".*hotline.*"'
)

for pattern in "${CRISIS_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock"); then
        echo "$matches"
        log_warn "Found hardcoded crisis resources (should be externalized)"
        ((WARNINGS++))
    fi
done

# Check for hardcoded persona information
log_info "Checking for hardcoded persona information..."

PERSONA_PATTERNS=(
    '".*Courage.*"'
    '".*Comfort.*"'
    '".*Creative.*"'
    '".*Compass.*"'
    '".*persona.*"'
)

for pattern in "${PERSONA_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock" | head -3); then
        echo "$matches"
        log_warn "Found hardcoded persona information (consider externalizing to config)"
        ((WARNINGS++))
    fi
done

# Check for magic numbers that should be constants
log_info "Checking for magic numbers..."

MAGIC_NUMBER_PATTERNS=(
    '\b20\s*\*\s*60\b'        # 20 minutes in seconds
    '\b1200\b'                # 20 minutes in seconds
    '\b13\b'                  # Age limit
    '\b17\b'                  # Max age
)

for pattern in "${MAGIC_NUMBER_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*" | head -3); then
        echo "$matches"
        log_warn "Found magic numbers (consider using named constants)"
        ((WARNINGS++))
    fi
done

# Check for print statements in production code
log_info "Checking for print statements..."

if matches=$(find . -name "*.swift" -exec grep -Hn "print(" {} \; | grep -v "//.*print" | grep -v "test\|Test\|debug\|Debug"); then
    echo "$matches" | head -5
    log_warn "Found print statements (use proper logging instead)"
    ((WARNINGS++))
fi

# Check for TODO/FIXME in strings
log_info "Checking for TODO/FIXME in user-facing strings..."

if matches=$(find . -name "*.swift" -exec grep -Hn '".*TODO\|".*FIXME\|".*XXX' {} \;); then
    echo "$matches"
    log_warn "Found TODO/FIXME in strings (should be completed before release)"
    ((WARNINGS++))
fi

# Summary
log_info "Hardcoded string check complete!"
log_info "Errors: $ERRORS"
log_info "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    log_error "Check failed with $ERRORS critical issues"
    exit 1
elif [[ $WARNINGS -gt 10 ]]; then
    log_warn "Many warnings found ($WARNINGS) - consider addressing them"
    exit 0
else
    log_info "Hardcoded string check passed!"
    exit 0
fi
