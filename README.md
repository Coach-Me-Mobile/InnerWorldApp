# InnerWorldApp

A mobile iOS AR app for teens (13+) featuring AI personas in a dreamlike, RealityKit-rendered environment for reflective conversations and personal growth.

## 🌟 Overview

InnerWorldApp creates a safe, private space where teens can engage with four distinct AI personas - Courage, Comfort, Creative, and Compass - within an anchored AR room. Each 20-minute daily session encourages meaningful self-reflection while promoting positive real-world behaviors.

## 🎯 Key Features

- **AR Dream Room**: Square room anchored in real environment using RealityKit
- **Four AI Personas**: Each with unique personality and interaction style
- **Privacy-First**: Per-user GraphRAG with Neo4j, no human review
- **Safety Built-In**: Crisis detection with US resource connections
- **Time-Limited**: 20 minutes/day to encourage healthy usage
- **Age-Appropriate**: Designed for teens 13+ with proper safeguards

## 🛡️ Security & Quality

This project implements comprehensive security and code quality measures:

### Pre-Commit Hooks
- **Gitleaks**: Secret detection and API key scanning
- **SwiftLint**: Swift code style and quality enforcement
- **Detect-Secrets**: Additional secret pattern detection
- **Custom Validators**: iOS project structure, API endpoints, crisis resources

### CI/CD Pipeline
- **Security Scanning**: Automated secret detection and vulnerability scanning
- **Code Quality**: SwiftLint, pre-commit hooks, and markdown linting
- **iOS Build & Test**: Multi-device testing on iPhone and iPad simulators
- **Privacy Compliance**: Hardcoded data detection and validation
- **Integration Tests**: Neo4j and API connectivity testing

## 🚀 Quick Start

### Prerequisites
- macOS with Xcode 15.1+
- iOS 17.0+ target
- Active Apple Developer account
- API keys for OpenAI/OpenRouter and Neo4j

### Setup Development Environment

1. **Clone and Setup**:
   ```bash
   git clone <repository-url>
   cd InnerWorldApp
   ./scripts/setup-dev-environment.sh
   ```

2. **Configure Environment**:
   ```bash
   cp .env.template .env
   # Edit .env with your API keys and configuration
   ```

3. **Install Pre-commit Hooks**:
   ```bash
   pre-commit install
   pre-commit run --all-files
   ```

4. **Validate Setup**:
   ```bash
   ./scripts/validate-ios-project.sh
   ```

## 🏗️ Architecture

### Tech Stack
- **iOS**: Swift, RealityKit, ARKit
- **Backend**: Cloud Neo4j Aura for GraphRAG
- **AI**: Claude (LLM), OpenAI (embeddings)
- **Distribution**: TestFlight for beta testing

### Project Structure
```
InnerWorldApp/
├── Sources/                    # Swift source code
├── Tests/                      # Unit, integration, and UI tests
├── Resources/                  # Assets, 3D models, configurations
├── documentation/              # Project documentation
├── scripts/                    # Development and validation scripts
├── fastlane/                   # Deployment automation
└── .github/workflows/          # CI/CD pipeline
```

## 🔒 Security Features

### Secret Management
- **Gitleaks Configuration**: Custom rules for OpenAI, Neo4j, iOS certificates
- **Environment Variables**: All secrets externalized
- **Keychain Integration**: Secure on-device storage
- **API Key Rotation**: Support for key rotation

### Crisis Safety
- **Detection**: ML-based crisis content identification
- **Response**: Immediate resource modal with hotlines
- **Privacy**: No human review, data minimization
- **Compliance**: Age-appropriate messaging and disclaimers

### Data Protection
- **GraphRAG**: Per-user knowledge graphs in Neo4j
- **Encryption**: Data encrypted in transit and at rest
- **Retention**: 30-day limit for free users
- **Deletion**: User-controlled data removal

## 👥 Personas

1. **Courage** - Bold motivator for facing challenges
2. **Comfort** - Empathetic supporter for difficult times
3. **Creative** - Playful idea generator for exploration
4. **Compass** - Values-based guide for decision making

## 🧪 Testing

### Run Tests
```bash
# Unit tests
xcodebuild test -scheme InnerWorldApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI tests
xcodebuild test -scheme InnerWorldApp -testPlan UITests

# Pre-commit validation
pre-commit run --all-files

# Custom validations
./scripts/validate-api-endpoints.sh
./scripts/check-hardcoded-strings.sh
./scripts/validate-crisis-resources.sh
```

### Fastlane Commands
```bash
# Run all tests
bundle exec fastlane test

# Build for testing
bundle exec fastlane build_for_testing

# Deploy to TestFlight
bundle exec fastlane beta
```

## 🚀 Deployment

### TestFlight Beta
1. Configure Apple Developer credentials in `fastlane/Appfile`
2. Run: `bundle exec fastlane beta`
3. Manage testers through App Store Connect

### App Store Release
- Follow Apple's review guidelines
- Ensure all privacy descriptions are complete
- Include crisis resource disclaimers

## 📋 Development Guidelines

### Commit Convention
```
type(scope): description

Types: feat, fix, docs, style, refactor, test, chore, security, crisis, persona, ar
Example: feat(personas): add Courage persona interaction
```

### Code Quality
- **SwiftLint**: Enforced via pre-commit hooks
- **Documentation**: Inline comments for all public APIs
- **Testing**: Minimum 80% code coverage
- **Security**: No hardcoded secrets or strings

### Crisis Feature Development
- All crisis-related code must pass validation scripts
- External configuration required for hotlines and resources
- Comprehensive testing for safety features
- Regular review of crisis detection accuracy

## 🤝 Contributing

1. Follow the commit convention
2. Run pre-commit hooks before committing
3. Ensure all tests pass
4. Update documentation for new features
5. Validate crisis features thoroughly

## 📄 License

This project is proprietary to GauntletAI. All rights reserved.

## 🆘 Crisis Resources

If you or someone you know is in crisis:
- **National Suicide Prevention Lifeline**: 988
- **Crisis Text Line**: Text HOME to 741741
- **Trevor Project** (LGBTQ+ youth): 1-866-488-7386

This app is not a substitute for professional mental health care.

---

**⚠️ Important**: This app is designed for teens 13+ and includes comprehensive safety measures. It is not therapy and should not replace professional mental health services.