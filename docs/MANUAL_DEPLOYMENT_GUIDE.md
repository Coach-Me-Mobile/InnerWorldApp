# InnerWorld Manual Deployment Guide

Complete manual deployment guide for InnerWorld infrastructure and iOS CI/CD pipeline.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Preparation](#preparation)
3. [Backend Infrastructure](#backend-infrastructure)
4. [Main Infrastructure Deployment](#main-infrastructure-deployment)
5. [GitHub Actions Configuration](#github-actions-configuration)
6. [Apple Certificates Setup](#apple-certificates-setup)
7. [Testing and Verification](#testing-and-verification)
8. [Cost Summary](#cost-summary)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- **AWS CLI** v2.x configured with administrator permissions
- **Terraform** >= 1.5.x
- **jq** for JSON processing
- **base64** encoding tool (usually pre-installed)
- **Git** for version control

### Required Accounts & Credentials
- **AWS Account** with administrator access
- **Apple Developer Account** ($99/year)
- **App Store Connect** access
- **OpenRouter API** account and key
- **GitHub repository** with admin access

### Verify Prerequisites
```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform --version

# Check jq
jq --version
```

## Preparation

### 1. Apple Developer Setup

**Get Apple Developer Team ID:**
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Sign in with your Apple ID
3. Navigate to **Membership** section
4. Copy your **Team ID** (10-character string)

**Create Apple Sign-In Key:**
1. Go to **Certificates, Identifiers & Profiles** > **Keys**
2. Click **+** to create new key
3. Enter name: "InnerWorld Sign In Key"
4. Check **Sign In with Apple**
5. Click **Continue** and **Register**
6. Download the `.p8` file
7. Note the **Key ID** (10-character string)

### 2. App Store Connect API Setup

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **Users and Access** > **Keys**
3. Click **+** to create new key
4. Enter name: "InnerWorld CI/CD Key"
5. Select **Developer** role
6. Click **Generate**
7. Download the `.p8` file
8. Note the **Key ID** and **Issuer ID**

**Get App ID:**
1. Go to **My Apps** in App Store Connect
2. Select your InnerWorld app (or create it)
3. Note the **App ID** (numerical value, e.g., 1234567890)

### 3. OpenRouter API Setup

1. Go to [OpenRouter](https://openrouter.ai/)
2. Create account or sign in
3. Navigate to **API Keys**
4. Create new key: "InnerWorld Production"
5. Copy the key (starts with `sk-or-v1-`)

### 4. Prepare Terraform Variables

```bash
cd infrastructure/environments/prod
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual values:

```hcl
# Project configuration
project_name = "innerworld"
environment  = "prod"
aws_region   = "us-east-1"

# Cost optimization settings (already configured for minimal cost)
enable_nat_gateway = true
single_nat_gateway = false  # Multi-AZ as requested

# REQUIRED: Replace with your actual credentials
apple_team_id     = "YOUR_APPLE_TEAM_ID"
apple_key_id      = "YOUR_APPLE_KEY_ID"
apple_private_key = "-----BEGIN PRIVATE KEY-----\nYOUR_APPLE_PRIVATE_KEY_CONTENT\n-----END PRIVATE KEY-----"
apple_client_id   = "com.gauntletai.innerworld"

app_store_connect_issuer_id   = "YOUR_ASC_ISSUER_ID"
app_store_connect_key_id      = "YOUR_ASC_KEY_ID"
app_store_connect_private_key = "-----BEGIN PRIVATE KEY-----\nYOUR_ASC_PRIVATE_KEY_CONTENT\n-----END PRIVATE KEY-----"
app_store_connect_app_id      = "YOUR_APP_ID"

openai_api_key = "sk-or-v1-YOUR-OPENROUTER-API-KEY"
```

**⚠️ Important**: For the private keys, include the full content of the `.p8` files with proper line breaks.

## Backend Infrastructure

Deploy the Terraform backend (S3 + DynamoDB) for state management:

```bash
cd infrastructure/shared

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy backend infrastructure
terraform apply

# Verify deployment
aws s3 ls | grep innerworld-prod-terraform-state
aws dynamodb list-tables | grep innerworld-prod-terraform-locks
```

## Main Infrastructure Deployment

Deploy the main application infrastructure:

```bash
cd ../environments/prod

# Initialize with backend
terraform init

# Review the deployment plan
terraform plan -var-file=terraform.tfvars

# Deploy infrastructure (this will take 10-15 minutes)
terraform apply -var-file=terraform.tfvars

# Verify key resources
terraform output
```

### Expected Resources Created

- **VPC** with multi-AZ subnets and NAT gateways
- **Cognito User Pool** for authentication
- **Lambda functions** for conversation handling
- **DynamoDB table** for live conversations
- **S3 buckets** for app assets and TestFlight builds
- **Secrets Manager** secrets for API keys
- **IAM user** and policies for GitHub Actions

## GitHub Actions Configuration

### 1. Get AWS Credentials for GitHub Actions

```bash
# Get the GitHub Actions credentials
terraform output github_actions_credentials

# This will output something like:
# {
#   "access_key_id" = "AKIA..."
#   "secret_access_key" = "..."
#   "region" = "us-east-1"
# }
```

### 2. Configure GitHub Repository Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these repository secrets:

#### AWS Credentials
```
AWS_ACCESS_KEY_ID = [access_key_id from terraform output]
AWS_SECRET_ACCESS_KEY = [secret_access_key from terraform output]
AWS_REGION = us-east-1
```

#### Build Configuration
```
BUILD_CONFIGURATION = Release
XCODE_VERSION = 15.1
```

#### S3 Buckets (get from terraform output)
```bash
terraform output s3
```
```
ASSETS_BUCKET_NAME = [app_assets_bucket from output]
TESTFLIGHT_BUCKET_NAME = [testflight_builds_bucket from output]
```

## Apple Certificates Setup

### 1. Export Certificates from Keychain

**Distribution Certificate:**
1. Open **Keychain Access**
2. Find your **iOS Distribution** certificate
3. Right-click → **Export**
4. Save as `.p12` file with a password
5. Convert to base64:
```bash
base64 -i YourCertificate.p12 | pbcopy
```

**Provisioning Profile:**
1. Download from Apple Developer Portal
2. Convert to base64:
```bash
base64 -i YourProfile.mobileprovision | pbcopy
```

### 2. Add to GitHub Secrets

```
IOS_CERTIFICATE_BASE64 = [base64 certificate content]
IOS_CERTIFICATE_PASSWORD = [certificate password]
IOS_PROVISIONING_PROFILE_BASE64 = [base64 profile content]
```

### 3. Update AWS Secrets Manager

The Terraform deployment created placeholder secrets. Update them with real values:

**Apple Sign-In credentials:**
```bash
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/apple/signin-key" \
  --secret-string '{
    "team_id": "YOUR_APPLE_TEAM_ID",
    "key_id": "YOUR_APPLE_KEY_ID",
    "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----",
    "client_id": "com.gauntletai.innerworld"
  }'
```

**App Store Connect API:**
```bash
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/appstoreconnect/api-key" \
  --secret-string '{
    "issuer_id": "YOUR_ASC_ISSUER_ID",
    "key_id": "YOUR_ASC_KEY_ID",
    "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_ASC_PRIVATE_KEY\n-----END PRIVATE KEY-----",
    "app_id": "YOUR_APP_ID",
    "bundle_id": "com.gauntletai.innerworld"
  }'
```

**OpenRouter API:**
```bash
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/openai/api-key" \
  --secret-string '{
    "api_key": "sk-or-v1-YOUR-OPENROUTER-KEY",
    "provider": "openrouter",
    "base_url": "https://openrouter.ai/api/v1",
    "model_primary": "anthropic/claude-3.5-sonnet",
    "model_fallback": "openai/gpt-4"
  }'
```

## Testing and Verification

### 1. Test AWS Access

```bash
# Test GitHub Actions user permissions
export AWS_ACCESS_KEY_ID=[from terraform output]
export AWS_SECRET_ACCESS_KEY=[from terraform output]

# Test S3 access
aws s3 ls s3://innerworld-prod-app-assets
aws s3 ls s3://innerworld-prod-testflight-builds

# Test Secrets Manager access
aws secretsmanager get-secret-value --secret-id "innerworld-prod/appstoreconnect/api-key"
```

### 2. Test Infrastructure

```bash
# Check all infrastructure components
terraform output | jq

# Verify Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `innerworld`)]'

# Verify Cognito User Pool
aws cognito-idp list-user-pools --max-items 10
```

### 3. Test CI/CD Pipeline

1. **Commit and push changes:**
```bash
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

2. **Monitor GitHub Actions:**
   - Go to your repository → **Actions** tab
   - Watch the iOS CI/CD workflow execution
   - Check each step for errors

3. **Verify TestFlight:**
   - Check [App Store Connect](https://appstoreconnect.apple.com/)
   - Navigate to **TestFlight** section
   - Verify new build appears

## Cost Summary

With this cost-optimized configuration:

### Monthly Infrastructure Costs (~$180)
- **Multi-AZ VPC with 3 NAT Gateways**: $135/month
- **DynamoDB (on-demand)**: $15/month
- **Lambda functions**: $20/month
- **S3 storage**: $5/month
- **Cognito**: FREE (up to 50K users)
- **Secrets Manager**: $3/month
- **CloudWatch (minimal)**: $2/month

### Additional Costs
- **Apple Developer Program**: $99/year
- **OpenRouter API**: Variable based on usage ($50-500/month)

### Cost Optimizations Applied
- ❌ VPC Flow Logs disabled (saves ~$15/month)
- ❌ Minimal CloudWatch logs (saves ~$10/month)
- ❌ Reduced backup retention (saves ~$10/month)
- ❌ Neptune GraphRAG disabled (saves ~$200/month)
- ✅ Multi-AZ NAT gateways maintained (as requested)

## Troubleshooting

### Common Issues

**Terraform State Lock:**
```bash
# If deployment gets stuck
terraform force-unlock [LOCK_ID]
```

**Certificate Issues:**
```bash
# Verify certificate format
security find-identity -v -p codesigning

# Check provisioning profile
security cms -D -i YourProfile.mobileprovision
```

**AWS Permissions:**
```bash
# Test AWS CLI configuration
aws sts get-caller-identity

# Test specific permissions
aws iam get-user
aws s3 ls
```

**GitHub Actions Failures:**
- Check repository secrets are correctly set
- Verify AWS credentials have proper permissions
- Ensure certificate and provisioning profile are valid
- Check Xcode version compatibility

### Useful Commands

```bash
# View all infrastructure outputs
terraform output -json | jq

# Monitor Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/innerworld

# Check S3 bucket policies
aws s3api get-bucket-policy --bucket innerworld-prod-app-assets

# Validate secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `innerworld`)]'
```

### Support Resources

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **GitHub Actions**: https://docs.github.com/en/actions
- **Apple Developer**: https://developer.apple.com/documentation/
- **AWS Documentation**: https://docs.aws.amazon.com/

---

## Next Steps

1. ✅ Deploy infrastructure manually using this guide
2. ✅ Configure GitHub Actions secrets
3. ✅ Test pipeline with a commit
4. ✅ Verify TestFlight deployment
5. 🔄 Monitor costs and optimize as needed
6. 🚀 Start iOS development with confidence

Your InnerWorld infrastructure is now ready for production iOS development and TestFlight deployment!
