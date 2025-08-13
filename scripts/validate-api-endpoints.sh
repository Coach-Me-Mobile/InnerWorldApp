#!/bin/bash
# validate-api-endpoints.sh
# Validate API endpoint configuration and security for InnerWorldApp

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

log_info "Validating API endpoint configuration..."

# Check for hardcoded API endpoints
log_info "Checking for hardcoded API endpoints..."

HARDCODED_ENDPOINTS=(
    '"https://api\.openai\.com[^"]*"'
    '"https://openrouter\.ai[^"]*"'
    '"neo4j\+s://[^"]*\.neo4j\.io[^"]*"'
    '"https://[^"]*\.amazonaws\.com[^"]*"'
    '"https://[^"]*\.firebase[^"]*\.com[^"]*"'
)

for pattern in "${HARDCODED_ENDPOINTS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock\|example"); then
        echo "$matches"
        log_error "Found hardcoded API endpoints (should use environment variables)"
        ((ERRORS++))
    fi
done

# Check for proper environment variable usage
log_info "Checking for environment variable usage..."

# First check if we have any Swift files to analyze
SWIFT_FILES=$(find . -name "*.swift" 2>/dev/null | wc -l)

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping Swift-specific validations (early development phase)"
else
    ENV_VAR_PATTERNS=(
        'ProcessInfo\.processInfo\.environment\["[^"]*"\]'
        'Bundle\.main\.object(forInfoDictionaryKey:'
        'getenv\('
        'Configuration\.'
        'Environment\.'
    )

    ENV_VARS_FOUND=false
    for pattern in "${ENV_VAR_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            ENV_VARS_FOUND=true
            break
        fi
    done

    if ! $ENV_VARS_FOUND; then
        log_warn "No environment variable usage found - API endpoints should be configurable"
        ((WARNINGS++))
    else
        log_info "Environment variable usage detected"
    fi
fi

# Check for SSL/TLS enforcement
log_info "Checking for SSL/TLS enforcement..."

HTTP_PATTERNS=(
    '"http://[^"]*"'
    'http://'
)

for pattern in "${HTTP_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "localhost\|127\.0\.0\.1\|test\|Test\|Mock"); then
        echo "$matches"
        log_error "Found non-HTTPS endpoints (all production endpoints should use HTTPS)"
        ((ERRORS++))
    fi
done

# Check for API key handling
log_info "Checking for proper API key handling..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping API key storage validation"
else
    API_KEY_HANDLING_PATTERNS=(
        'Keychain'
        'kSecClass'
        'SecItemAdd'
        'SecItemCopyMatching'
        'UserDefaults'  # This should be flagged as insecure
    )

    SECURE_STORAGE_FOUND=false
    INSECURE_STORAGE_FOUND=false

    for pattern in "${API_KEY_HANDLING_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            if [[ "$pattern" == "UserDefaults" ]]; then
                if matches=$(find . -name "*.swift" -exec grep -Hn "UserDefaults.*[aA][pP][iI].*[kK][eE][yY]\|UserDefaults.*[sS][eE][cC][rR][eE][tT]\|UserDefaults.*[tT][oO][kK][eE][nN]" {} \;); then
                    echo "$matches"
                    log_error "Found API keys stored in UserDefaults (insecure)"
                    ((ERRORS++))
                    INSECURE_STORAGE_FOUND=true
                fi
            else
                SECURE_STORAGE_FOUND=true
            fi
        fi
    done

    if $SECURE_STORAGE_FOUND; then
        log_info "Secure storage (Keychain) usage detected"
    elif ! $INSECURE_STORAGE_FOUND; then
        log_warn "No API key storage mechanism found"
        ((WARNINGS++))
    fi
fi

# Check for proper error handling in API calls
log_info "Checking for API error handling..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping API error handling validation"
else
    ERROR_HANDLING_PATTERNS=(
        'do\s*\{[\s\S]*\}\s*catch'
        'Result<.*,.*Error>'
        '\.sink\s*\(\s*receiveCompletion:\s*\{\s*completion\s*in'
        'URLSessionDataTask'
        'HTTPURLResponse'
    )

    ERROR_HANDLING_FOUND=false
    for pattern in "${ERROR_HANDLING_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            ERROR_HANDLING_FOUND=true
            break
        fi
    done

    if $ERROR_HANDLING_FOUND; then
        log_info "API error handling detected"
    else
        log_warn "No API error handling found"
        ((WARNINGS++))
    fi
fi

# Check for rate limiting implementation
log_info "Checking for rate limiting..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping rate limiting validation"
else
    RATE_LIMITING_PATTERNS=(
        'rateLimit'
        'throttle'
        'debounce'
        'semaphore'
        'DispatchSemaphore'
        'Timer'
    )

    RATE_LIMITING_FOUND=false
    for pattern in "${RATE_LIMITING_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            RATE_LIMITING_FOUND=true
            break
        fi
    done

    if $RATE_LIMITING_FOUND; then
        log_info "Rate limiting implementation detected"
    else
        log_warn "No rate limiting found - important for API cost control"
        ((WARNINGS++))
    fi
fi

# Check for timeout configuration
log_info "Checking for timeout configuration..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping timeout validation"
else
    TIMEOUT_PATTERNS=(
        'timeoutInterval'
        'timeout'
        'requestTimeout'
    )

    TIMEOUT_FOUND=false
    for pattern in "${TIMEOUT_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            TIMEOUT_FOUND=true
            break
        fi
    done

    if $TIMEOUT_FOUND; then
        log_info "Timeout configuration detected"
    else
        log_warn "No timeout configuration found"
        ((WARNINGS++))
    fi
fi

# Check for retry mechanisms
log_info "Checking for retry mechanisms..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping retry mechanism validation"
else
    RETRY_PATTERNS=(
        'retry'
        'attempt'
        'backoff'
        'exponential'
    )

    RETRY_FOUND=false
    for pattern in "${RETRY_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            RETRY_FOUND=true
            break
        fi
    done

    if $RETRY_FOUND; then
        log_info "Retry mechanism detected"
    else
        log_warn "No retry mechanism found - important for reliability"
        ((WARNINGS++))
    fi
fi

# Check for API versioning
log_info "Checking for API versioning..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping API versioning validation"
else
    VERSIONING_PATTERNS=(
        '/v[0-9]'
        'version'
        'api.*version'
    )

    VERSIONING_FOUND=false
    for pattern in "${VERSIONING_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            VERSIONING_FOUND=true
            break
        fi
    done

    if $VERSIONING_FOUND; then
        log_info "API versioning detected"
    else
        log_warn "No API versioning found - important for backward compatibility"
        ((WARNINGS++))
    fi
fi

# Check for proper logging of API calls
log_info "Checking for API call logging..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping API logging validation"
else
    LOGGING_PATTERNS=(
        'Logger'
        'os_log'
        'NSLog'
        'log\.'
    )

    LOGGING_FOUND=false
    for pattern in "${LOGGING_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            LOGGING_FOUND=true
            break
        fi
    done

    if $LOGGING_FOUND; then
        log_info "Logging implementation detected"
    else
        log_warn "No logging found - important for debugging API issues"
        ((WARNINGS++))
    fi
fi

# Check for API response validation
log_info "Checking for API response validation..."

if [[ $SWIFT_FILES -eq 0 ]]; then
    log_info "No Swift files found - skipping API response validation"
else
    VALIDATION_PATTERNS=(
        'Codable'
        'JSONDecoder'
        'JSONSerialization'
        'validate'
        'schema'
    )

    VALIDATION_FOUND=false
    for pattern in "${VALIDATION_PATTERNS[@]}"; do
        if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
            VALIDATION_FOUND=true
            break
        fi
    done

    if $VALIDATION_FOUND; then
        log_info "API response validation detected"
    else
        log_warn "No API response validation found"
        ((WARNINGS++))
    fi
fi

# Summary
log_info "API endpoint validation complete!"
log_info "Errors: $ERRORS"
log_info "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    log_error "Validation failed with $ERRORS critical security issues"
    exit 1
elif [[ $WARNINGS -gt 8 ]]; then
    log_warn "Many warnings found ($WARNINGS) - consider addressing them for better API reliability"
    exit 0
else
    log_info "API endpoint validation passed!"
    exit 0
fi
