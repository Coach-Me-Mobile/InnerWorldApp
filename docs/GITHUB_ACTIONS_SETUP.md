# InnerWorld iOS CI/CD with GitHub Actions

Complete setup guide for automated iOS CI/CD using GitHub Actions for TestFlight deployment.

## Overview

GitHub Actions provides a much better solution for iOS CI/CD compared to AWS CodePipeline:

### ✅ **Advantages of GitHub Actions:**
- **Native macOS Runners**: Xcode pre-installed with iOS simulators
- **Cost-Effective**: Free for public repos, $0.08/minute for private (vs CodePipeline $1/month + build costs)
- **Better iOS Support**: Native Xcode, fastlane, TestFlight tools
- **Easier Configuration**: YAML workflows in repository
- **Rich Marketplace**: Thousands of pre-built actions
- **Better Debugging**: Real-time logs and artifact downloads

### 🏗️ **Infrastructure Architecture:**
- **AWS Backend**: Cognito, Lambda, DynamoDB, S3 (unchanged)
- **GitHub Actions**: iOS build, test, and deployment pipeline
- **AWS Integration**: S3 artifact storage, Secrets Manager for credentials

## Prerequisites

### 1. AWS Infrastructure
- Terraform infrastructure deployed (S3, Secrets, Cognito, Lambda, DynamoDB)
- AWS credentials for GitHub Actions created
- Apple Developer and App Store Connect credentials stored in AWS Secrets Manager

### 2. Apple Developer Requirements
- Apple Developer Program membership
- App registered in App Store Connect
- Code signing certificates
- Provisioning profiles
- App Store Connect API key

### 3. GitHub Repository Setup
- Repository with iOS project
- Admin access to configure secrets
- Branch protection rules (recommended)

## Step 1: Deploy AWS Infrastructure

### 1.1 Deploy Infrastructure with GitHub Actions Support

```bash
cd infrastructure/environments/prod

# Configure terraform.tfvars
cat > terraform.tfvars << EOF
# Project Configuration
project_name = "innerworld"
environment  = "prod"
aws_region   = "us-east-1"

# Networking (Multi-AZ NAT for production)
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true
single_nat_gateway = false

# Apple Credentials (stored in AWS Secrets Manager)
apple_team_id     = "YOUR_TEAM_ID"
apple_key_id      = "YOUR_KEY_ID"
apple_private_key = "YOUR_PRIVATE_KEY"
apple_client_id   = "com.gauntletai.innerworld"

# App Store Connect API
app_store_connect_issuer_id   = "YOUR_ISSUER_ID"
app_store_connect_key_id      = "YOUR_KEY_ID"
app_store_connect_private_key = "YOUR_PRIVATE_KEY"
app_store_connect_app_id      = "YOUR_APP_ID"

# OpenRouter API
openai_api_key = "sk-or-v1-YOUR-KEY"
EOF

# Deploy infrastructure
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### 1.2 Retrieve GitHub Actions Credentials

After deployment, get the AWS credentials for GitHub Actions:

```bash
# Get AWS credentials (store these securely)
terraform output -json github_actions_credentials

# Example output:
{
  "access_key_id": "AKIA...",
  "secret_access_key": "xxx...", 
  "region": "us-east-1"
}
```

## Step 2: Configure GitHub Repository Secrets

### 2.1 Required GitHub Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions

**AWS Credentials:**
```
AWS_ACCESS_KEY_ID = AKIA... (from terraform output)
AWS_SECRET_ACCESS_KEY = xxx... (from terraform output)
```

**Apple Code Signing (Base64 encoded):**
```
APPLE_CERTIFICATE_P12_BASE64 = MII... (your .p12 certificate in base64)
APPLE_CERTIFICATE_PASSWORD = your_certificate_password
APPLE_PROVISIONING_PROFILE_BASE64 = MII... (your .mobileprovision in base64)
```

### 2.2 Encode Apple Certificates

Convert your Apple certificates to base64:

```bash
# Convert certificate to base64
base64 -i YourCertificate.p12 -o certificate_base64.txt

# Convert provisioning profile to base64  
base64 -i YourProfile.mobileprovision -o profile_base64.txt

# Copy the base64 content to GitHub secrets
cat certificate_base64.txt
cat profile_base64.txt
```

### 2.3 Optional Notification Secrets

For Slack/Teams notifications (optional):
```
SLACK_WEBHOOK_URL = https://hooks.slack.com/... (optional)
TEAMS_WEBHOOK_URL = https://outlook.office.com/... (optional)
```

## Step 3: Verify iOS Project Configuration

### 3.1 Required iOS Project Structure

```
ios/
├── InnerWorld.xcodeproj       # Xcode project
├── InnerWorld/
│   ├── AppDelegate.swift
│   ├── Info.plist            # Contains version info
│   └── ...
├── InnerWorldTests/          # Unit tests
│   └── InnerWorldTests.swift
├── InnerWorldUITests/        # UI tests  
│   └── InnerWorldUITests.swift
└── Podfile (optional)        # CocoaPods dependencies
```

### 3.2 Update Info.plist

Ensure your `ios/InnerWorld/Info.plist` has version keys:

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 3.3 Configure Xcode Scheme

1. Open your Xcode project
2. Edit Scheme → "InnerWorld"
3. Ensure "Shared" is checked
4. Build Configuration: Release for Archive
5. Test configuration should include your test targets

## Step 4: Understand the CI/CD Pipeline

### 4.1 Pipeline Triggers

The workflow triggers on:
- **Push to main/develop**: Full pipeline with TestFlight deployment (main only)
- **Pull Requests**: Build and test only (no deployment)
- **Manual Trigger**: Option to force TestFlight deployment or skip tests

### 4.2 Pipeline Stages

#### **1. Setup & Validation** (Ubuntu runner)
- Generate build numbers and version info
- Validate iOS project structure
- Determine if deployment should occur

#### **2. Build** (macOS runner with Xcode)
- Cache derived data for faster builds
- Install CocoaPods dependencies (if needed)
- Update version and build numbers in Info.plist
- Build for testing (Debug configuration)
- Archive for release (Release configuration)
- Upload build artifacts

#### **3. Test** (macOS runner)
- Run unit tests with code coverage
- Generate test reports and coverage badges
- Post test results to PR comments
- Validate 80% code coverage threshold

#### **4. Code Signing & Export** (macOS runner)
- Download build artifacts from previous stage
- Retrieve Apple certificates from AWS Secrets Manager
- Import certificates and provisioning profiles
- Export signed IPA file
- Upload IPA to S3 for artifact storage
- Create build manifest with metadata

#### **5. TestFlight Deployment** (macOS runner)
- Download signed IPA
- Retrieve App Store Connect API key from AWS
- Upload to TestFlight using altool
- Create deployment summary
- Send notifications (if configured)

#### **6. Cleanup**
- Clean up keychains and temporary files
- Provide pipeline summary

## Step 5: Test the Pipeline

### 5.1 Trigger First Build

```bash
# Make a small change and push to trigger pipeline
echo "# Test" >> README.md
git add README.md
git commit -m "feat: test GitHub Actions iOS CI/CD pipeline"
git push origin main
```

### 5.2 Monitor Pipeline Execution

1. Go to GitHub repository → Actions tab
2. Click on the running workflow
3. Monitor each job in real-time
4. Download artifacts if needed

### 5.3 Check TestFlight

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → TestFlight
3. Verify the build appears and is processing
4. Add release notes and distribute to testers

## Step 6: Pipeline Configuration

### 6.1 Environment Variables

Key environment variables in the workflow:

```yaml
env:
  XCODE_VERSION: '15.1'              # Xcode version
  IOS_SIMULATOR_DEVICE: 'iPhone 15 Pro'  # Test device
  SCHEME_NAME: 'InnerWorld'          # Xcode scheme
  BUILD_CONFIGURATION: 'Release'     # Build config
  AWS_REGION: 'us-east-1'           # AWS region
  S3_BUCKET_BUILDS: 'innerworld-prod-testflight-builds'
```

### 6.2 Customization Options

**Skip Tests:**
```bash
# Manual trigger with skip tests option
gh workflow run ios-cicd.yml --field skip_tests=true
```

**Force TestFlight Deployment:**
```bash
# Deploy from any branch
gh workflow run ios-cicd.yml --field deploy_to_testflight=true
```

**Update Xcode Version:**
Edit `.github/workflows/ios-cicd.yml`:
```yaml
env:
  XCODE_VERSION: '15.2'  # Update to newer version
```

## Step 7: Advanced Configuration

### 7.1 Branch Protection Rules

Recommended GitHub branch protection for `main`:

1. Repository Settings → Branches
2. Add rule for `main` branch:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Required status checks: `Build iOS App`, `Test iOS App`
   - ✅ Restrict pushes that create files larger than 100MB

### 7.2 Artifact Management

**S3 Storage Structure:**
```
s3://innerworld-prod-testflight-builds/
├── builds/
│   ├── a1b2c3d4/                 # Build number (git commit hash)
│   │   ├── InnerWorld.ipa
│   │   └── build-manifest.json
│   └── e5f6g7h8/
│       ├── InnerWorld.ipa
│       └── build-manifest.json
```

**Artifact Retention:**
- GitHub Actions artifacts: 30-90 days
- S3 TestFlight builds: 90 days (configurable)
- Test results: 30 days

### 7.3 Notifications

**Slack Integration Example:**
Add to workflow after successful deployment:

```yaml
- name: Notify Slack
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: success
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
    text: "🚀 InnerWorld iOS build ${{ needs.setup.outputs.build_number }} deployed to TestFlight!"
```

## Troubleshooting

### Common Issues

#### 1. **Code Signing Failures**
```
Error: No profiles for 'com.gauntletai.innerworld' were found
```
**Solution:**
- Verify provisioning profile is valid and not expired
- Check bundle ID matches exactly
- Ensure certificate is properly base64 encoded

#### 2. **TestFlight Upload Failures**
```
Error: App Store Connect API authentication failed
```
**Solution:**
- Verify App Store Connect API key is valid
- Check issuer ID and key ID are correct
- Ensure API key has TestFlight access permissions

#### 3. **Build Timeouts**
```
Error: The job running on runner GitHub Actions X has exceeded the maximum execution time
```
**Solution:**
- Increase timeout in workflow (default: 360 minutes)
- Optimize build caching
- Consider breaking into smaller jobs

#### 4. **AWS Secrets Access Denied**
```
Error: Access denied to secrets manager
```
**Solution:**
- Verify AWS credentials in GitHub secrets
- Check IAM policy permissions
- Ensure secrets exist in the correct AWS region

### Debug Commands

**Check workflow logs:**
```bash
# List recent workflow runs
gh run list --workflow=ios-cicd.yml

# View specific run logs
gh run view [RUN_ID] --log

# Download artifacts
gh run download [RUN_ID]
```

**AWS CLI debugging:**
```bash
# Test AWS credentials
aws sts get-caller-identity

# Check S3 bucket access
aws s3 ls s3://innerworld-prod-testflight-builds/

# Verify secrets access
aws secretsmanager get-secret-value --secret-id innerworld-prod/appstoreconnect/api-key
```

## Cost Analysis

### GitHub Actions Costs
- **Public repositories**: Free (unlimited minutes)
- **Private repositories**: 
  - 2,000 free minutes/month
  - macOS runners: $0.08/minute
  - Typical iOS build: ~10-15 minutes
  - **Estimated cost**: $5-15/month for active development

### Comparison with CodePipeline
| Service | Monthly Cost | iOS Support | Ease of Use |
|---------|-------------|-------------|-------------|
| **GitHub Actions** | $5-15 | ✅ Native | ✅ Excellent |
| **AWS CodePipeline** | $50-100+ | ❌ Limited | ❌ Complex |

### Cost Optimization Tips
1. **Use caching** for derived data and dependencies
2. **Skip tests** for draft builds when appropriate
3. **Limit parallel jobs** if you have many repositories
4. **Use self-hosted runners** for high-volume usage (advanced)

## Best Practices

### 1. **Security**
- Never commit certificates or keys to repository
- Use environment-specific secrets
- Rotate App Store Connect API keys regularly
- Enable branch protection and required reviews

### 2. **Performance**
- Cache derived data and dependencies
- Use specific Xcode versions to avoid surprises
- Parallelize independent jobs when possible
- Monitor build times and optimize bottlenecks

### 3. **Reliability**
- Add retry logic for flaky network operations
- Use specific action versions (not @main)
- Test workflow changes on feature branches
- Monitor Apple Developer Portal for certificate expiry

### 4. **Monitoring**
- Set up notifications for failed builds
- Monitor TestFlight upload success rates
- Track build performance metrics
- Review and rotate credentials regularly

## Next Steps

### 1. **Enhanced Testing**
- Add more comprehensive unit tests
- Implement UI test automation
- Add performance testing
- Code quality gates (SwiftLint, etc.)

### 2. **Advanced Deployment**
- Staging environment deployment
- Blue/green backend deployments
- Feature flag integration
- A/B testing setup

### 3. **Production Readiness**
- App Store release automation
- Release notes generation
- Version management
- Rollback capabilities

## Support

For issues with GitHub Actions:
1. Check workflow logs in GitHub repository
2. Verify AWS credentials and permissions
3. Test Apple certificate validity
4. Contact GauntletAI development team

**Useful Links:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Cloud vs GitHub Actions](https://docs.github.com/en/actions/deployment/deploying-xcode-applications)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

---

**GitHub Actions provides a superior iOS CI/CD experience with native macOS support, better cost efficiency, and easier maintenance compared to AWS CodePipeline. This setup scales from individual development to enterprise deployment seamlessly.**
