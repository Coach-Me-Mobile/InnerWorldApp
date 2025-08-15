# Local CI/CD Testing Guide

## 🎯 Overview

This guide explains how to test your CI/CD pipeline locally before pushing to avoid the frustrating cycle of:
```
Push → CI Fails → Fix → Push → CI Fails → Repeat...
```

## 🧪 Available Testing Methods

### 1. iOS Local Testing (Primary Method)

The most reliable way to test iOS builds locally since it runs on the same macOS environment as CI.

#### Quick Commands

```bash
# Full iOS CI/CD testing (recommended before push)
./scripts/ci-test.sh ios

# Quick build verification only (faster)
./scripts/ci-test.sh ios-quick

# Clean build + full testing (if having cache issues)  
./scripts/ci-test.sh ios-clean

# Verbose output for debugging
./scripts/ci-test.sh ios-verbose

# Validate project structure
./scripts/ci-test.sh validate
```

#### Manual Testing

```bash
# Run the full testing script directly
./scripts/test-ios-ci-locally.sh

# With environment variables
VERBOSE=true CLEAN_BUILD=true ./scripts/test-ios-ci-locally.sh
```

### 2. GitHub Actions Testing (Limited)

Uses the `act` tool to run GitHub Actions locally. Limited for iOS since it requires macOS.

```bash
# Setup act (one-time)
./scripts/ci-test.sh setup-act

# Try to run GitHub Actions locally
./scripts/ci-test.sh github-actions
```

**Note**: iOS builds require macOS, so `act` (which runs in containers) has limitations. Use the iOS-specific testing instead.

## 📋 Testing Workflow

### Before Every Push

1. **Validate project**: `./scripts/ci-test.sh validate`
2. **Quick build check**: `./scripts/ci-test.sh ios-quick`
3. **Full testing** (if quick passed): `./scripts/ci-test.sh ios`
4. **Push with confidence** 🚀

### When Debugging CI Issues

1. **Clean testing**: `./scripts/ci-test.sh ios-clean`
2. **Verbose output**: `./scripts/ci-test.sh ios-verbose`
3. **Compare local vs CI**: Check the CI logs against local output

### Continuous Development

```bash
# During development - quick checks
./scripts/ci-test.sh ios-quick

# Before major changes - full validation  
./scripts/ci-test.sh ios

# Before release - comprehensive testing
CLEAN_BUILD=true RUN_TESTS=true ./scripts/test-ios-ci-locally.sh
```

## 🔧 What the Local Testing Covers

### ✅ Covered by Local Testing

- **iOS Build Compilation**: Exact same commands as CI
- **Swift Compilation Errors**: All syntax and type errors
- **Dependency Resolution**: Package and framework issues
- **Deployment Target Issues**: macOS/iOS version compatibility
- **Code Signing Settings**: Disabled for CI compatibility
- **ARKit Detection**: Adapts testing strategy accordingly
- **Mac Catalyst Support**: Uses when available for testing
- **Unit Tests**: Runs when possible (excludes UI tests on Mac Catalyst)

### ⚠️ Limitations (CI-Specific Issues)

- **Runner Environment**: Different Xcode versions between local/CI
- **Specific Simulator Availability**: CI may have different simulators
- **Exact CI Runner State**: Clean environment differences
- **Network Dependencies**: CI may have different network access

## 🛠️ Troubleshooting

### Common Issues & Solutions

#### "xcpretty not found"
```bash
gem install xcpretty
# Or let the script install it automatically
```

#### "xcodebuild command not found"
```bash
# Install Xcode from App Store
# Ensure Command Line Tools are installed
xcode-select --install
```

#### "Destination not found" 
```bash
# Check available destinations
cd ios && xcodebuild -project InnerWorld.xcodeproj -scheme InnerWorld -showdestinations
```

#### Tests failing locally but not in CI
```bash
# Try clean build
./scripts/ci-test.sh ios-clean

# Check for local environment differences
VERBOSE=true ./scripts/test-ios-ci-locally.sh
```

## 📊 Test Output Explanation

### Exit Codes
- `0`: All tests passed ✅
- `1`: Build or test failure ❌

### Key Phases
1. **Prerequisites Check**: Validates tools and project structure
2. **Destination Detection**: Finds available simulators/devices
3. **Build for Testing**: Compiles the project for testing
4. **Test Execution**: Runs unit tests (when possible)
5. **Release Build**: Verifies release configuration

### Test Modes
- `mac_catalyst`: Uses Mac Catalyst for testing (ARKit apps)
- `simulator`: Uses iOS Simulator (non-ARKit apps)
- `build_only`: Build verification only (limited destinations)

## 🚀 Integration with Development Workflow

### Pre-commit Hook (Optional)

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running iOS CI tests before commit..."
./scripts/ci-test.sh ios-quick
```

### Makefile Integration

Add to `Makefile`:
```makefile
.PHONY: test-ci test-ios-quick test-ios-full

test-ci: test-ios-quick

test-ios-quick:
	./scripts/ci-test.sh ios-quick

test-ios-full:
	./scripts/ci-test.sh ios
```

Usage: `make test-ci`

## 💡 Best Practices

1. **Always test locally** before pushing to main/production branches
2. **Use quick tests** during active development
3. **Run full tests** before important commits
4. **Clean build** if you encounter mysterious issues  
5. **Check CI logs** if local tests pass but CI fails
6. **Keep dependencies updated** between local and CI environments

## 🔄 Updating Testing Scripts

The testing scripts are designed to mirror the CI/CD pipeline exactly. When updating:

1. **Update both** CI workflow and local scripts together
2. **Test the changes** using the local scripts first
3. **Document any new requirements** in this guide
4. **Validate** that local and CI behavior match

---

## 📞 Need Help?

- **Local testing issues**: Check the troubleshooting section above
- **CI/CD pipeline questions**: Review the GitHub Actions workflow in `.github/workflows/ios-cicd.yml`
- **iOS build problems**: Use verbose mode for detailed error messages

**Remember**: These local tests can catch 90%+ of CI issues before you push! 🎯
