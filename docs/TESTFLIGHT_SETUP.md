# TestFlight Deployment Setup Guide

This guide walks you through setting up CI/CD for InnerWorld iOS app deployment to TestFlight.

## Prerequisites

Before you start, ensure you have:

1. **Apple Developer Account** (paid) with admin access
2. **App Store Connect access** with App Manager role or higher
3. **GitHub repository** with the InnerWorld code
4. **AWS Account** with appropriate permissions for infrastructure deployment

## Part 1: Infrastructure Setup (Minimal)

### 1.1 Deploy Minimal AWS Infrastructure

The infrastructure has been streamlined for minimal TestFlight deployment. Only essential components are enabled:

- ✅ **AWS Cognito** - User authentication
- ✅ **AWS Secrets Manager** - API key storage
- ✅ **AWS VPC** - Basic networking
- ❌ **Neptune** - Commented out (GraphRAG not needed for auth testing)
- ❌ **DynamoDB** - Commented out (conversation storage not needed)
- ❌ **Lambda functions** - Commented out (backend APIs not needed for auth testing)

#### Deploy Development Environment

```bash
# Navigate to dev environment
cd infrastructure/environments/dev

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (leave Apple credentials empty for now)

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

#### Get Cognito Configuration

After deployment, get the Cognito configuration for your iOS app:

```bash
# Get Cognito outputs
terraform output cognito_info
```

Save these values - you'll need them for GitHub Secrets:
- `user_pool_id`
- `user_pool_client_id` 
- `identity_pool_id`
- `user_pool_domain`

## Part 2: Apple Developer Setup

### 2.1 Create App Store Connect App

1. **Login to App Store Connect**: https://appstoreconnect.apple.com
2. **Create New App**:
   - Platform: iOS
   - Name: InnerWorld
   - Primary Language: English
   - Bundle ID: `com.gauntletai.innerworld` (or your preferred bundle ID)
   - SKU: `innerworld-ios`

### 2.2 Create Certificates and Provisioning Profiles

#### Development Certificate
```bash
# Create development certificate signing request
openssl req -new -newkey rsa:2048 -nodes -keyout development.key -out development.csr

# Upload CSR to Apple Developer Portal and download certificate
# Convert to P12 format
openssl pkcs12 -export -out development.p12 -inkey development.key -in development.cer
```

#### Distribution Certificate
```bash
# Create distribution certificate signing request
openssl req -new -newkey rsa:2048 -nodes -keyout distribution.key -out distribution.csr

# Upload CSR to Apple Developer Portal and download certificate
# Convert to P12 format
openssl pkcs12 -export -out distribution.p12 -inkey distribution.key -in distribution.cer
```

#### Provisioning Profiles
1. **Development Profile**: Create in Apple Developer Portal for your app bundle ID
2. **Distribution Profile**: Create for App Store distribution

### 2.3 Create App Store Connect API Key

1. **Go to Users and Access** → **Keys** in App Store Connect
2. **Create API Key**:
   - Name: "InnerWorld CI/CD"
   - Access: App Manager
   - Download the `.p8` file
3. **Note down**:
   - Key ID
   - Issuer ID

## Part 3: GitHub Repository Setup

### 3.1 Configure Repository Secrets

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

#### Apple Certificates and Profiles
```bash
# Convert certificates and profiles to base64
base64 -i development.p12 | pbcopy  # Copy to clipboard
base64 -i distribution.p12 | pbcopy
base64 -i development.mobileprovision | pbcopy
base64 -i distribution.mobileprovision | pbcopy
base64 -i AuthKey_KEYID.p8 | pbcopy
```

**GitHub Secrets to add:**
- `BUILD_CERTIFICATE_BASE64`: Development certificate (base64)
- `P12_PASSWORD`: Development certificate password
- `BUILD_PROVISION_PROFILE_BASE64`: Development provisioning profile (base64)
- `DISTRIBUTION_CERTIFICATE_BASE64`: Distribution certificate (base64)
- `DISTRIBUTION_P12_PASSWORD`: Distribution certificate password
- `DISTRIBUTION_PROVISION_PROFILE_BASE64`: Distribution provisioning profile (base64)
- `KEYCHAIN_PASSWORD`: Any secure password for CI keychain

#### Apple Developer Info
- `APPLE_TEAM_ID`: Your Apple Developer Team ID
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API Key ID
- `APP_STORE_CONNECT_API_ISSUER_ID`: App Store Connect API Issuer ID
- `APP_STORE_CONNECT_API_KEY_BASE64`: App Store Connect API Key (.p8 file as base64)

#### AWS Cognito Configuration
- `COGNITO_USER_POOL_ID`: From Terraform output
- `COGNITO_USER_POOL_CLIENT_ID`: From Terraform output
- `COGNITO_IDENTITY_POOL_ID`: From Terraform output
- `AWS_REGION`: AWS region (e.g., "us-east-1")

### 3.2 Update iOS Project Configuration

#### Bundle Identifier
Update the bundle identifier in Xcode to match your App Store Connect app:
1. Open `ios/InnerWorld.xcodeproj`
2. Select target → General → Bundle Identifier
3. Set to `com.gauntletai.innerworld` (or your chosen bundle ID)

#### Team and Signing
1. Select your Apple Developer Team
2. Enable "Automatically manage signing"
3. Verify provisioning profiles are correctly assigned

#### Version and Build Numbers
1. Set Version to `1.0.0`
2. Set Build Number to `1`
3. Enable "Agvtool" for automatic build number increments

## Part 4: Test the Pipeline

### 4.1 Manual Trigger (Recommended for first test)

1. **Go to Actions tab** in your GitHub repository
2. **Select "iOS TestFlight Deployment"** workflow
3. **Click "Run workflow"**
4. **Set "Deploy to TestFlight" to true**
5. **Monitor the build** progress in Actions tab

### 4.2 Automatic Trigger

Push changes to the `main` branch in the `ios/` directory to automatically trigger the workflow.

```bash
# Example: Make a small change to trigger deployment
echo "// TestFlight deployment test" >> ios/InnerWorld/AppDelegate.swift
git add .
git commit -m "Test TestFlight deployment"
git push origin main
```

## Part 5: Verify TestFlight Deployment

### 5.1 Check App Store Connect

1. **Login to App Store Connect**
2. **Go to your app** → **TestFlight**
3. **Verify the build** appears in "iOS Builds"
4. **Add internal testers** or submit for external testing

### 5.2 Test Installation

1. **Install TestFlight app** on your iOS device
2. **Accept TestFlight invitation** (email from App Store Connect)
3. **Install and test** the InnerWorld app
4. **Verify Cognito authentication** works correctly

## Part 6: Troubleshooting

### Common Issues

#### Build Failures
- **Certificate/Profile mismatch**: Verify bundle IDs match exactly
- **Signing issues**: Check that certificates are valid and not expired
- **Xcode version**: Ensure GitHub Actions uses compatible Xcode version

#### TestFlight Upload Failures
- **API Key issues**: Verify App Store Connect API key has correct permissions
- **Bundle validation**: Check for missing required metadata
- **Version conflicts**: Ensure build numbers are unique

#### Cognito Integration Issues
- **Configuration mismatch**: Verify GitHub secrets match Terraform outputs
- **Region settings**: Ensure AWS region is consistent across configuration
- **Identity pool**: Verify identity pool is correctly configured

### Debug Commands

```bash
# Check Terraform outputs
cd infrastructure/environments/dev
terraform output

# Verify GitHub secrets (from Actions logs)
echo "Checking Cognito configuration..."
echo "User Pool ID: ${{ secrets.COGNITO_USER_POOL_ID }}"

# Test local iOS build
cd ios
xcodebuild clean build -project InnerWorld.xcodeproj -scheme InnerWorld
```

### Log Analysis

Check GitHub Actions logs for detailed error messages:
1. **Build and Test job**: Compilation and unit test issues
2. **Deploy TestFlight job**: Certificate, signing, and upload issues

## Part 7: Next Steps

### Enable Full Backend (Optional)

Once TestFlight deployment is working, you can enable the full backend:

1. **Uncomment modules** in `infrastructure/main.tf`:
   - Neptune (GraphRAG)
   - DynamoDB (conversation storage)
   - Lambda (backend APIs)

2. **Update environment configuration** with backend endpoints

3. **Configure Apple Sign-In** (if desired):
   ```bash
   # Add Apple credentials to terraform.tfvars
   apple_team_id     = "YOUR_TEAM_ID"
   apple_key_id      = "YOUR_KEY_ID"
   apple_client_id   = "com.gauntletai.innerworld"
   apple_private_key = "YOUR_PRIVATE_KEY"
   ```

### Production Deployment

1. **Create production environment**:
   ```bash
   # Deploy to production
   cd infrastructure/environments/prod
   cp terraform.tfvars.example terraform.tfvars
   # Configure production values
   terraform init
   terraform apply
   ```

2. **Update iOS project** for production endpoints

3. **Submit to App Store** for public release

## Support

For issues with this setup:
1. Check GitHub Actions logs for detailed error messages
2. Verify all secrets are correctly configured
3. Ensure Apple Developer certificates are valid
4. Confirm AWS infrastructure is properly deployed

---

**This setup provides a minimal but functional CI/CD pipeline for InnerWorld iOS TestFlight deployment with AWS Cognito authentication.**
