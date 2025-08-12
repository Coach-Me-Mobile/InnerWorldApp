#!/bin/bash
# validate-crisis-resources.sh
# Validate crisis resource handling for teen mental health app

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

log_info "Validating crisis resource handling for teen safety..."

# Check for hardcoded crisis hotline numbers
log_info "Checking for hardcoded crisis hotline numbers..."

CRISIS_NUMBER_PATTERNS=(
    '".*988.*"'
    '".*1-800-273-8255.*"'  # Old suicide prevention number
    '".*1-866-488-7386.*"'  # Trevor Project
    '".*741741.*"'          # Crisis Text Line
    '".*1-800-[0-9]{3}-[0-9]{4}.*"'  # General 1-800 numbers
    '".*\+1-[0-9]{3}-[0-9]{3}-[0-9]{4}.*"'  # International format
)

for pattern in "${CRISIS_NUMBER_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock\|example"); then
        echo "$matches"
        log_error "Found hardcoded crisis hotline numbers (should be externalized to config)"
        ((ERRORS++))
    fi
done

# Check for hardcoded crisis organization names
log_info "Checking for hardcoded crisis organization names..."

CRISIS_ORG_PATTERNS=(
    '".*National Suicide Prevention.*"'
    '".*Trevor Project.*"'
    '".*Crisis Text Line.*"'
    '".*SAMHSA.*"'
    '".*Mental Health America.*"'
    '".*NAMI.*"'
)

for pattern in "${CRISIS_ORG_PATTERNS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock\|comment"); then
        echo "$matches"
        log_warn "Found hardcoded crisis organization names (consider externalizing for easier updates)"
        ((WARNINGS++))
    fi
done

# Check for proper crisis detection keywords
log_info "Checking for crisis detection implementation..."

CRISIS_DETECTION_PATTERNS=(
    'suicide'
    'self.*harm'
    'kill.*myself'
    'hurt.*myself'
    'end.*it.*all'
    'crisis'
    'emergency'
    'depression'
    'anxiety'
)

CRISIS_DETECTION_FOUND=false
for pattern in "${CRISIS_DETECTION_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        CRISIS_DETECTION_FOUND=true
        break
    fi
done

if $CRISIS_DETECTION_FOUND; then
    log_info "Crisis detection keywords found"
    
    # Check if these are hardcoded or externalized
    if find . -name "*.swift" -exec grep -Hn '".*suicide.*"\|".*self.*harm.*"\|".*kill.*myself.*"' {} \; | grep -v "//.*\"" | grep -q .; then
        log_warn "Crisis keywords appear to be hardcoded (consider using ML models or external config)"
        ((WARNINGS++))
    fi
else
    log_warn "No crisis detection implementation found - required for teen safety"
    ((WARNINGS++))
fi

# Check for proper crisis response mechanism
log_info "Checking for crisis response mechanism..."

CRISIS_RESPONSE_PATTERNS=(
    'modal'
    'alert'
    'emergency'
    'crisis.*response'
    'safety.*plan'
    'help.*resources'
)

CRISIS_RESPONSE_FOUND=false
for pattern in "${CRISIS_RESPONSE_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        CRISIS_RESPONSE_FOUND=true
        break
    fi
done

if $CRISIS_RESPONSE_FOUND; then
    log_info "Crisis response mechanism detected"
else
    log_warn "No crisis response mechanism found - required for teen safety"
    ((WARNINGS++))
fi

# Check for age-appropriate messaging
log_info "Checking for age-appropriate crisis messaging..."

INAPPROPRIATE_TERMS=(
    '".*kill.*"'
    '".*die.*"'
    '".*death.*"'
    '".*suicide.*"'
)

for pattern in "${INAPPROPRIATE_TERMS[@]}"; do
    if matches=$(find . -name "*.swift" -exec grep -Hn "$pattern" {} \; | grep -v "//.*\"" | grep -v "test\|Test\|Mock" | head -3); then
        echo "$matches"
        log_warn "Found potentially triggering language (ensure age-appropriate messaging)"
        ((WARNINGS++))
    fi
done

# Check for proper escalation procedures
log_info "Checking for escalation procedures..."

ESCALATION_PATTERNS=(
    'escalate'
    'priority'
    'urgent'
    'immediate'
    'emergency.*contact'
    'guardian'
    'parent'
)

ESCALATION_FOUND=false
for pattern in "${ESCALATION_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        ESCALATION_FOUND=true
        break
    fi
done

if $ESCALATION_FOUND; then
    log_info "Escalation procedures detected"
else
    log_warn "No escalation procedures found - important for serious situations"
    ((WARNINGS++))
fi

# Check for professional disclaimer
log_info "Checking for professional disclaimer..."

DISCLAIMER_PATTERNS=(
    'not.*therapy'
    'not.*medical.*advice'
    'professional.*help'
    'qualified.*professional'
    'emergency.*services'
)

DISCLAIMER_FOUND=false
for pattern in "${DISCLAIMER_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        DISCLAIMER_FOUND=true
        break
    fi
done

if $DISCLAIMER_FOUND; then
    log_info "Professional disclaimer detected"
else
    log_warn "No professional disclaimer found - legally required"
    ((WARNINGS++))
fi

# Check for data handling in crisis situations
log_info "Checking for crisis data handling..."

CRISIS_DATA_PATTERNS=(
    'crisis.*log'
    'emergency.*data'
    'sensitive.*information'
    'privacy.*crisis'
    'anonymize'
    'delete.*crisis'
)

CRISIS_DATA_FOUND=false
for pattern in "${CRISIS_DATA_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        CRISIS_DATA_FOUND=true
        break
    fi
done

if $CRISIS_DATA_FOUND; then
    log_info "Crisis data handling detected"
else
    log_warn "No crisis data handling found - important for privacy compliance"
    ((WARNINGS++))
fi

# Check for internationalization support
log_info "Checking for internationalization of crisis resources..."

INTL_PATTERNS=(
    'Localizable\.strings'
    'NSLocalizedString'
    'locale'
    'country.*code'
    'region'
)

INTL_FOUND=false
for pattern in "${INTL_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        INTL_FOUND=true
        break
    fi
done

if $INTL_FOUND; then
    log_info "Internationalization support detected"
else
    log_warn "No internationalization found - crisis resources vary by region"
    ((WARNINGS++))
fi

# Check for accessibility in crisis features
log_info "Checking for accessibility in crisis features..."

ACCESSIBILITY_PATTERNS=(
    'accessibilityLabel.*crisis'
    'accessibilityHint.*emergency'
    'VoiceOver.*crisis'
    'emergency.*accessibility'
)

CRISIS_ACCESSIBILITY_FOUND=false
for pattern in "${ACCESSIBILITY_PATTERNS[@]}"; do
    if find . -name "*.swift" -exec grep -l "$pattern" {} \; | grep -q .; then
        CRISIS_ACCESSIBILITY_FOUND=true
        break
    fi
done

if $CRISIS_ACCESSIBILITY_FOUND; then
    log_info "Crisis accessibility features detected"
else
    log_warn "No crisis accessibility features found - important for inclusive safety"
    ((WARNINGS++))
fi

# Check for testing of crisis features
log_info "Checking for crisis feature testing..."

if find . -name "*Test*.swift" -exec grep -l "crisis\|emergency\|safety" {} \; | grep -q .; then
    log_info "Crisis feature testing detected"
else
    log_warn "No crisis feature testing found - critical features should be well-tested"
    ((WARNINGS++))
fi

# Check for crisis resource configuration files
log_info "Checking for external crisis resource configuration..."

CRISIS_CONFIG_FILES=(
    "crisis-resources.json"
    "emergency-contacts.plist"
    "safety-resources.json"
    "hotlines.json"
    "Resources/crisis-resources.json"
    "Config/crisis-resources.plist"
)

CRISIS_CONFIG_FOUND=false
for file in "${CRISIS_CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        CRISIS_CONFIG_FOUND=true
        log_info "Found crisis configuration file: $file"
        break
    fi
done

if ! $CRISIS_CONFIG_FOUND; then
    log_warn "No external crisis resource configuration found - consider externalizing for easier updates"
    ((WARNINGS++))
fi

# Summary
log_info "Crisis resource validation complete!"
log_info "Errors: $ERRORS"
log_info "Warnings: $WARNINGS"

# Special recommendations for crisis handling
if [[ $ERRORS -gt 0 ]] || [[ $WARNINGS -gt 5 ]]; then
    log_warn ""
    log_warn "CRISIS SAFETY RECOMMENDATIONS:"
    log_warn "1. Externalize all crisis hotline numbers to configuration files"
    log_warn "2. Use ML-based detection instead of hardcoded keywords"
    log_warn "3. Implement proper escalation procedures"
    log_warn "4. Include clear disclaimers about not being therapy"
    log_warn "5. Support multiple regions/languages for crisis resources"
    log_warn "6. Ensure crisis features are accessible"
    log_warn "7. Test crisis features thoroughly"
    log_warn ""
fi

if [[ $ERRORS -gt 0 ]]; then
    log_error "Crisis resource validation failed with $ERRORS critical issues"
    exit 1
elif [[ $WARNINGS -gt 8 ]]; then
    log_warn "Many warnings found ($WARNINGS) - teen safety features need attention"
    exit 0
else
    log_info "Crisis resource validation passed!"
    exit 0
fi
