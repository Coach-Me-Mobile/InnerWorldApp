#!/bin/bash
# setup-dev-environment.sh
# Setup development environment for InnerWorldApp

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS development"
    exit 1
fi

log_info "Setting up InnerWorldApp development environment..."

# Check for Xcode
log_step "Checking Xcode installation..."
if ! command -v xcodebuild &> /dev/null; then
    log_error "Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1 | awk '{print $2}')
log_info "Found Xcode version: $XCODE_VERSION"

# Check for Homebrew
log_step "Checking Homebrew installation..."
if ! command -v brew &> /dev/null; then
    log_warn "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    log_info "Homebrew found, updating..."
    brew update
fi

# Install development tools
log_step "Installing development tools..."

# Essential tools
TOOLS=(
    "swiftlint"
    "gitleaks"
    "pre-commit"
    "fastlane"
    "xcpretty"
    "markdownlint-cli"
)

for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        log_info "Installing $tool..."
        case $tool in
            "pre-commit")
                pip3 install pre-commit
                ;;
            "markdownlint-cli")
                npm install -g markdownlint-cli
                ;;
            *)
                brew install "$tool"
                ;;
        esac
    else
        log_info "$tool is already installed"
    fi
done

# Install Python dependencies for pre-commit hooks
log_step "Installing Python dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install --user detect-secrets black
else
    log_warn "pip3 not found. Some pre-commit hooks may not work."
fi

# Install Node.js if needed (for markdownlint)
log_step "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    log_info "Installing Node.js via Homebrew..."
    brew install node
fi

# Install RubyGems for Fastlane
log_step "Setting up Fastlane..."
if command -v gem &> /dev/null; then
    gem install fastlane --user-install
else
    log_warn "Ruby/gem not found. Fastlane may not work properly."
fi

# Setup pre-commit hooks
log_step "Setting up pre-commit hooks..."
if [[ -f ".pre-commit-config.yaml" ]]; then
    pre-commit install
    pre-commit install --hook-type commit-msg
    log_info "Pre-commit hooks installed successfully"
else
    log_warn ".pre-commit-config.yaml not found. Run this script from the project root."
fi

# Setup Git hooks
log_step "Setting up additional Git hooks..."
git config --local core.hooksPath .githooks
mkdir -p .githooks

# Create commit message hook
cat > .githooks/commit-msg << 'EOF'
#!/bin/bash
# commit-msg hook to enforce commit message format

commit_regex='^(feat|fix|docs|style|refactor|test|chore|security|crisis|persona|ar)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format!"
    echo "Format: type(scope): description"
    echo "Types: feat, fix, docs, style, refactor, test, chore, security, crisis, persona, ar"
    echo "Example: feat(personas): add Courage persona interaction"
    exit 1
fi

# Check for backslashes in commit message (can break formatting)
if grep -q '\\' "$1"; then
    echo "Error: Commit message contains backslashes which can break formatting"
    exit 1
fi
EOF

chmod +x .githooks/commit-msg

# Setup IDE configurations
log_step "Setting up IDE configurations..."

# Create .vscode settings if VSCode is used
if command -v code &> /dev/null; then
    mkdir -p .vscode
    cat > .vscode/settings.json << 'EOF'
{
    "swift.autoGenerateSwiftInterface": true,
    "swift.backgroundCompilation": true,
    "files.associations": {
        "*.swift": "swift"
    },
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "swiftlint.enable": true,
    "swiftlint.configPath": ".swiftlint.yml"
}
EOF
    log_info "VSCode settings configured"
fi

# Setup environment template
log_step "Creating environment template..."
if [[ ! -f ".env.template" ]]; then
    cat > .env.template << 'EOF'
# Environment variables template for InnerWorldApp
# Copy this file to .env and fill in your actual values

# OpenAI/OpenRouter API Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1

# Neo4j Database Configuration
NEO4J_URI=neo4j+s://your-neo4j-instance.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your_neo4j_password_here
NEO4J_DATABASE=neo4j

# App Configuration
APP_ENVIRONMENT=development
SESSION_TIME_LIMIT_MINUTES=20
MIN_AGE_REQUIREMENT=13
MAX_AGE_REQUIREMENT=17

# Crisis Resources Configuration
CRISIS_RESOURCES_URL=https://your-crisis-resources-api.com/v1
ENABLE_CRISIS_DETECTION=true

# Analytics Configuration (optional)
ANALYTICS_ENABLED=false
ANALYTICS_API_KEY=your_analytics_key_here

# Development Configuration
DEBUG_LOGGING=true
MOCK_API_RESPONSES=false
SKIP_AGE_VERIFICATION=false
EOF
    log_info "Environment template created"
fi

# Setup testing directories
log_step "Setting up testing structure..."
mkdir -p Tests/UnitTests
mkdir -p Tests/IntegrationTests
mkdir -p Tests/UITests
mkdir -p Tests/Mocks

# Create sample test files
if [[ ! -f "Tests/UnitTests/SampleTest.swift" ]]; then
    cat > Tests/UnitTests/SampleTest.swift << 'EOF'
import XCTest
@testable import InnerWorldApp

final class SampleTest: XCTestCase {
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssertTrue(true)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
EOF
fi

# Setup documentation structure
log_step "Setting up documentation structure..."
mkdir -p documentation/{api,architecture,deployment,privacy,safety}

# Create documentation templates
DOCS=(
    "documentation/api/README.md"
    "documentation/architecture/README.md"
    "documentation/deployment/README.md"
    "documentation/privacy/privacy-policy.md"
    "documentation/safety/crisis-resources.md"
)

for doc in "${DOCS[@]}"; do
    if [[ ! -f "$doc" ]]; then
        touch "$doc"
        echo "# $(basename "$doc" .md)" > "$doc"
        echo "" >> "$doc"
        echo "TODO: Add content for $(basename "$doc" .md)" >> "$doc"
    fi
done

# Setup Fastlane
log_step "Setting up Fastlane..."
if [[ ! -d "fastlane" ]]; then
    mkdir -p fastlane
    
    cat > fastlane/Fastfile << 'EOF'
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(scheme: "InnerWorldApp")
  end

  desc "Build for testing"
  lane :build_for_testing do
    build_app(
      scheme: "InnerWorldApp",
      configuration: "Debug",
      skip_package_ipa: true,
      skip_archive: true
    )
  end

  desc "Upload to TestFlight"
  lane :beta do
    build_app(scheme: "InnerWorldApp")
    upload_to_testflight
  end
end
EOF

    cat > fastlane/Appfile << 'EOF'
app_identifier("com.gauntletai.innerworldapp")
apple_id("your-apple-id@example.com")
team_id("YOUR_TEAM_ID")
EOF
    
    log_info "Fastlane configuration created"
fi

# Run initial validation
log_step "Running initial validation..."
if [[ -f "scripts/validate-ios-project.sh" ]]; then
    ./scripts/validate-ios-project.sh || log_warn "Initial validation found issues - this is normal for new projects"
fi

# Final setup
log_step "Final setup steps..."

# Test pre-commit installation
if command -v pre-commit &> /dev/null; then
    log_info "Testing pre-commit hooks..."
    pre-commit run --all-files || log_warn "Pre-commit hooks found issues - this is normal for initial setup"
fi

# Create initial secrets baseline for detect-secrets
if command -v detect-secrets &> /dev/null; then
    log_info "Creating initial secrets baseline..."
    detect-secrets scan --baseline .secrets.baseline || true
fi

log_info ""
log_info "✅ Development environment setup complete!"
log_info ""
log_info "Next steps:"
log_info "1. Copy .env.template to .env and fill in your API keys"
log_info "2. Create your Xcode project in this directory"
log_info "3. Update fastlane/Appfile with your Apple Developer details"
log_info "4. Run 'pre-commit run --all-files' to test the setup"
log_info "5. Commit your changes: git add . && git commit -m 'chore: setup development environment'"
log_info ""
log_info "Important files created:"
log_info "- .env.template (copy to .env and configure)"
log_info "- .vscode/settings.json (VSCode configuration)"
log_info "- fastlane/ (deployment automation)"
log_info "- Tests/ (testing structure)"
log_info "- documentation/ (project documentation)"
log_info ""
log_info "Security features enabled:"
log_info "- Gitleaks secret scanning"
log_info "- Pre-commit hooks for code quality"
log_info "- SwiftLint for code style"
log_info "- Crisis resource validation"
log_info "- API endpoint security checks"
log_info ""
log_warn "Remember: Never commit real API keys or secrets!"
log_info ""
