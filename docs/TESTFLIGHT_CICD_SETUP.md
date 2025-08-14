# InnerWorld iOS TestFlight CI/CD Setup Guide

This guide walks you through setting up CI/CD for InnerWorld iOS app deployment to TestFlight using AWS CodePipeline.

## Overview

The infrastructure has been streamlined for TestFlight deployment with the following key changes:

### ✅ **What's Included for TestFlight:**
- **VPC & Networking**: Multi-AZ VPC with NAT gateways for secure communication
- **AWS Cognito**: Apple Sign-In and email authentication 
- **Lambda Functions**: WebSocket API handlers for real-time chat
- **DynamoDB**: Real-time conversation storage with TTL
- **S3 Buckets**: App assets storage and TestFlight build artifacts
- **iOS CI/CD Pipeline**: Automated build, test, and TestFlight deployment
- **Secrets Management**: Apple Developer and App Store Connect credentials

### ❌ **Temporarily Disabled (Cost Optimization):**
- **Neptune GraphRAG**: Expensive ($526/month) - can be enabled later when needed

## Prerequisites

### 1. AWS Account Setup
- AWS CLI configured with appropriate permissions
- Terraform >= 1.5 installed
- Access to create AWS resources (VPC, Lambda, DynamoDB, etc.)

### 2. Apple Developer Account
- Apple Developer Program membership
- App registered in App Store Connect
- Signing certificates and provisioning profiles configured

### 3. GitHub Repository
- Repository access for CodePipeline integration
- Branch protection rules configured (recommended)

## Step 1: Create GitHub Connection for CodePipeline

AWS CodePipeline requires a GitHub connection to access your repository.

### 1.1 Create CodeStar Connection (AWS Console)

```bash
# Navigate to AWS CodePipeline console
# Go to Settings > Connections
# Click "Create connection"
# Choose "GitHub" as provider
# Follow the OAuth flow to connect your GitHub account
# Note the connection ARN for terraform.tfvars
```

**Alternative CLI Method:**
```bash
aws codestar-connections create-connection \
  --provider-type GitHub \
  --connection-name "innerworld-github-connection"

# Note the connection ARN from the output
```

### 1.2 Authorize the Connection
After creating the connection, you must authorize it in the AWS console:
1. Go to CodePipeline > Settings > Connections
2. Find your connection and click "Update pending connection"
3. Complete the GitHub authorization flow

## Step 2: Configure Apple Developer Credentials

### 2.1 Apple Developer Team Information
You'll need:
- **Team ID**: Found in Apple Developer Account > Membership
- **Bundle ID**: Your app's bundle identifier (e.g., `com.gauntletai.innerworld`)
- **Signing Certificate**: For code signing

### 2.2 App Store Connect API Key
Create an API key for TestFlight uploads:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to Users and Access > Keys
3. Click "Generate API Key"
4. Download the `.p8` file and note:
   - **Issuer ID**
   - **Key ID** 
   - **Private Key** (contents of .p8 file)

## Step 3: Deploy Infrastructure

### 3.1 Configure Terraform Variables

Create `infrastructure/environments/prod/terraform.tfvars`:

```hcl
# Project Configuration
project_name = "innerworld"
environment  = "prod"
aws_region   = "us-east-1"

# Networking
vpc_cidr            = "10.0.0.0/16"
enable_nat_gateway  = true
single_nat_gateway  = false  # Multi-AZ for production

# Feature Flags
enable_ios_pipeline = true
enable_codepipeline = false  # Disable legacy pipeline

# GitHub Configuration
github_connection_arn = "arn:aws:codestar-connections:us-east-1:ACCOUNT:connection/CONNECTION-ID"
github_repository     = "GauntletAI/InnerWorldApp"
github_branch         = "main"

# Apple Credentials (will be stored in AWS Secrets Manager)
# Note: These are sensitive and will be replaced with actual values
apple_team_id     = "YOUR_TEAM_ID"
apple_key_id      = "YOUR_KEY_ID"
apple_private_key = "YOUR_PRIVATE_KEY"
apple_client_id   = "com.gauntletai.innerworld"

# App Store Connect API
app_store_connect_issuer_id   = "YOUR_ISSUER_ID"
app_store_connect_key_id      = "YOUR_KEY_ID"
app_store_connect_private_key = "YOUR_PRIVATE_KEY"
app_store_connect_app_id      = "YOUR_APP_ID"

# OpenRouter API Key
openai_api_key = "sk-or-v1-YOUR-OPENROUTER-KEY"

# Logging
log_retention_days = 14
```

### 3.2 Deploy Backend State Infrastructure

First, create the Terraform backend:

```bash
cd infrastructure/shared
terraform init
terraform plan
terraform apply
```

### 3.3 Deploy Main Infrastructure

```bash
cd infrastructure/environments/prod

# Initialize with remote state backend
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Deploy infrastructure
terraform apply -var-file="terraform.tfvars"
```

### 3.4 Update Secrets in AWS Secrets Manager

After deployment, update the placeholder secrets with real values:

```bash
# Update Apple Developer credentials
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/apple/signin-key" \
  --secret-string '{
    "team_id": "YOUR_ACTUAL_TEAM_ID",
    "key_id": "YOUR_ACTUAL_KEY_ID", 
    "private_key": "YOUR_ACTUAL_PRIVATE_KEY",
    "client_id": "com.gauntletai.innerworld"
  }'

# Update App Store Connect API credentials
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/appstoreconnect/api-key" \
  --secret-string '{
    "issuer_id": "YOUR_ACTUAL_ISSUER_ID",
    "key_id": "YOUR_ACTUAL_KEY_ID",
    "private_key": "YOUR_ACTUAL_PRIVATE_KEY", 
    "app_id": "YOUR_ACTUAL_APP_ID",
    "bundle_id": "com.gauntletai.innerworld"
  }'

# Update OpenRouter API key
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/openai/api-key" \
  --secret-string '{
    "api_key": "sk-or-v1-YOUR-ACTUAL-KEY",
    "provider": "openrouter",
    "base_url": "https://openrouter.ai/api/v1",
    "model_primary": "anthropic/claude-3.5-sonnet",
    "model_fallback": "openai/gpt-4"
  }'
```

## Step 4: Test the CI/CD Pipeline

### 4.1 Verify Infrastructure

Check that all resources were created:

```bash
# Check pipeline status
aws codepipeline get-pipeline-state --name innerworld-prod-ios-pipeline

# Check S3 buckets
aws s3 ls | grep innerworld-prod

# Verify secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `innerworld-prod`)]'
```

### 4.2 Trigger First Build

Push a commit to your main branch to trigger the pipeline:

```bash
git add .
git commit -m "feat: trigger iOS CI/CD pipeline"
git push origin main
```

### 4.3 Monitor Pipeline Execution

```bash
# Watch pipeline progress
aws codepipeline get-pipeline-execution \
  --pipeline-name innerworld-prod-ios-pipeline \
  --pipeline-execution-id EXECUTION_ID

# View build logs
aws logs tail /aws/codebuild/innerworld-prod-ios-build --follow
```

## Step 5: iOS Project Configuration

### 5.1 Update iOS Project for CI/CD

Ensure your iOS project is configured for automated building:

1. **Signing Configuration**: Set up automatic signing or manual signing with provisioning profiles
2. **Build Schemes**: Ensure the "InnerWorld" scheme is shared and builds correctly
3. **Test Configuration**: Add unit tests and UI tests for the pipeline

### 5.2 Required iOS Project Structure

```
ios/
├── InnerWorld.xcodeproj
├── InnerWorld/
│   ├── AppDelegate.swift
│   ├── Info.plist
│   └── ...
├── InnerWorldTests/
│   └── InnerWorldTests.swift
└── InnerWorldUITests/
    └── InnerWorldUITests.swift
```

## Pipeline Stages Explained

### 1. **Source Stage**
- Triggered by commits to main branch
- Downloads source code from GitHub
- Creates source artifacts

### 2. **Build Stage** 
- Runs `buildspecs/ios-build.yml`
- Builds iOS app with Xcode
- Creates signed IPA file
- Uploads artifacts to S3

### 3. **Test Stage**
- Runs `buildspecs/ios-test.yml` 
- Executes unit tests, integration tests, UI tests
- Generates code coverage reports
- Validates app quality

### 4. **Manual Approval** (Production only)
- Requires manual approval before TestFlight deployment
- Review build artifacts and test results

### 5. **TestFlight Deploy Stage**
- Runs `buildspecs/testflight-deploy.yml`
- Uploads IPA to App Store Connect
- Submits build to TestFlight
- Notifies team of successful deployment

## Monitoring and Troubleshooting

### Pipeline Monitoring

```bash
# Check pipeline status
aws codepipeline list-pipeline-executions --pipeline-name innerworld-prod-ios-pipeline

# View specific build logs
aws logs get-log-events --log-group-name /aws/codebuild/innerworld-prod-ios-build

# Check build failures
aws codebuild batch-get-builds --ids $(aws codebuild list-builds-for-project --project-name innerworld-prod-ios-build --query 'ids[0]' --output text)
```

### Common Issues

#### 1. **GitHub Connection Failed**
```bash
# Verify connection is authorized
aws codestar-connections get-connection --connection-arn YOUR_CONNECTION_ARN
```

#### 2. **Apple Credentials Invalid**
```bash
# Test secrets retrieval
aws secretsmanager get-secret-value --secret-id innerworld-prod/appstoreconnect/api-key
```

#### 3. **Build Failures**
- Check buildspec syntax
- Verify Xcode project configuration
- Ensure signing certificates are valid

### Cost Monitoring

Current infrastructure costs (without Neptune):
- **DynamoDB**: ~$25/month (on-demand)
- **Lambda**: ~$50/month (conversation processing)
- **S3**: ~$10/month (app assets + builds)
- **CodePipeline**: ~$15/month (pipeline executions)
- **Other AWS services**: ~$40/month
- **Total**: ~$140/month (vs $666/month with Neptune)

## Next Steps

### 1. **Enable Additional Features** (When Ready)
```bash
# Uncomment Neptune module in main.tf for GraphRAG
# Update terraform.tfvars to enable Neptune
# Run terraform apply
```

### 2. **Production Readiness**
- Set up CloudWatch alarms and monitoring
- Configure SNS notifications for pipeline events
- Add blue/green deployment for backend services
- Set up staging environment

### 3. **Security Enhancements**
- Enable AWS Config for compliance monitoring
- Set up AWS GuardDuty for threat detection
- Configure VPC Flow Logs analysis

## Support

For infrastructure issues:
1. Check CloudWatch logs: `/aws/lambda/innerworld-prod-*`
2. Review CodeBuild logs: `/aws/codebuild/innerworld-prod-*`
3. Monitor DynamoDB metrics in CloudWatch console
4. Contact the GauntletAI infrastructure team

---

**This infrastructure is optimized for TestFlight deployment with a cost-effective architecture that can scale to full production when GraphRAG features are needed.**
