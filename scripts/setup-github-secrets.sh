#!/bin/bash

# =============================================================================
# GITHUB SECRETS SETUP SCRIPT
# =============================================================================
# Helper script to prepare secrets for GitHub Actions
# Run this after deploying Terraform infrastructure
# =============================================================================

set -e

echo "🔐 GitHub Actions Secrets Setup Helper"
echo "======================================="

# Check if we're in the right directory
if [ ! -f "infrastructure/main.tf" ]; then
  echo "❌ Error: Run this script from the project root directory"
  exit 1
fi

# Step 1: Get AWS credentials from Terraform
echo ""
echo "📊 Step 1: Getting AWS credentials from Terraform..."
cd infrastructure/environments/prod

if [ ! -f "terraform.tfstate" ]; then
  echo "❌ Error: Terraform state not found. Deploy infrastructure first:"
  echo "   terraform apply -var-file=terraform.tfvars"
  exit 1
fi

echo "Getting GitHub Actions AWS credentials..."
AWS_CREDS=$(terraform output -json github_actions_credentials 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$AWS_CREDS" ]; then
  echo "❌ Error: Could not get AWS credentials from Terraform"
  echo "   Make sure infrastructure is deployed with: terraform apply"
  exit 1
fi

ACCESS_KEY_ID=$(echo "$AWS_CREDS" | jq -r '.access_key_id')
SECRET_ACCESS_KEY=$(echo "$AWS_CREDS" | jq -r '.secret_access_key')
REGION=$(echo "$AWS_CREDS" | jq -r '.region')

echo "✅ AWS credentials retrieved successfully"
echo "   Access Key ID: $ACCESS_KEY_ID"
echo "   Region: $REGION"

cd ../../..

# Step 2: Check for Apple certificates
echo ""
echo "📱 Step 2: Checking for Apple certificates..."

CERT_FILE=""
PROFILE_FILE=""

# Look for common certificate file names
for cert in *.p12 ios_distribution.p12 distribution.p12 cert.p12; do
  if [ -f "$cert" ]; then
    CERT_FILE="$cert"
    break
  fi
done

# Look for common provisioning profile names
for profile in *.mobileprovision InnerWorld.mobileprovision; do
  if [ -f "$profile" ]; then
    PROFILE_FILE="$profile"
    break
  fi
done

# Step 3: Convert certificates to base64
echo ""
echo "🔄 Step 3: Converting certificates to base64..."

if [ -n "$CERT_FILE" ] && [ -f "$CERT_FILE" ]; then
  echo "Converting certificate: $CERT_FILE"
  CERT_BASE64=$(base64 -i "$CERT_FILE")
  echo "✅ Certificate converted to base64"
else
  echo "⚠️  No .p12 certificate file found"
  echo "   Place your iOS Distribution certificate (.p12) in project root"
  CERT_BASE64="REPLACE_WITH_YOUR_CERTIFICATE_BASE64"
fi

if [ -n "$PROFILE_FILE" ] && [ -f "$PROFILE_FILE" ]; then
  echo "Converting provisioning profile: $PROFILE_FILE"
  PROFILE_BASE64=$(base64 -i "$PROFILE_FILE")
  echo "✅ Provisioning profile converted to base64"
else
  echo "⚠️  No .mobileprovision file found"
  echo "   Place your App Store provisioning profile (.mobileprovision) in project root"
  PROFILE_BASE64="REPLACE_WITH_YOUR_PROVISIONING_PROFILE_BASE64"
fi

# Step 4: Generate secrets summary
echo ""
echo "📋 Step 4: GitHub Secrets Summary"
echo "=================================="

cat > github-secrets-setup.md << EOF
# GitHub Actions Secrets Setup

Add these secrets to your GitHub repository:
**Settings → Secrets and variables → Actions**

## Required Secrets

### AWS Credentials (from Terraform)
\`\`\`
AWS_ACCESS_KEY_ID = $ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY = $SECRET_ACCESS_KEY
\`\`\`

### Apple Code Signing
\`\`\`
APPLE_CERTIFICATE_P12_BASE64 = $CERT_BASE64
APPLE_CERTIFICATE_PASSWORD = YOUR_CERTIFICATE_PASSWORD
APPLE_PROVISIONING_PROFILE_BASE64 = $PROFILE_BASE64
\`\`\`



## AWS Secrets Manager (managed by Terraform)

Update these in AWS Console or via CLI:

### Apple Developer Credentials
\`\`\`bash
aws secretsmanager update-secret \\
  --secret-id "innerworld-prod/apple/signin-key" \\
  --secret-string '{
    "team_id": "YOUR_APPLE_TEAM_ID",
    "key_id": "YOUR_APPLE_KEY_ID",
    "private_key": "YOUR_APPLE_PRIVATE_KEY",
    "client_id": "com.gauntletai.innerworld"
  }'
\`\`\`

### App Store Connect API
\`\`\`bash
aws secretsmanager update-secret \\
  --secret-id "innerworld-prod/appstoreconnect/api-key" \\
  --secret-string '{
    "issuer_id": "YOUR_ASC_ISSUER_ID",
    "key_id": "YOUR_ASC_KEY_ID",
    "private_key": "YOUR_ASC_PRIVATE_KEY",
    "app_id": "YOUR_APP_ID",
    "bundle_id": "com.gauntletai.innerworld"
  }'
\`\`\`

### OpenRouter API
\`\`\`bash
aws secretsmanager update-secret \\
  --secret-id "innerworld-prod/openai/api-key" \\
  --secret-string '{
    "api_key": "sk-or-v1-YOUR-OPENROUTER-KEY",
    "provider": "openrouter",
    "base_url": "https://openrouter.ai/api/v1",
    "model_primary": "anthropic/claude-3.5-sonnet",
    "model_fallback": "openai/gpt-4"
  }'
\`\`\`

## Next Steps

1. **Add secrets to GitHub repository** (copy values above)
2. **Update AWS Secrets Manager** with real Apple/OpenRouter credentials
3. **Test the pipeline** by pushing to main branch
4. **Verify TestFlight deployment** in App Store Connect

## Verification Commands

\`\`\`bash
# Test AWS credentials
aws sts get-caller-identity

# Check secrets access
aws secretsmanager get-secret-value --secret-id innerworld-prod/appstoreconnect/api-key

# Trigger pipeline
git push origin main
\`\`\`
EOF

echo "✅ Secrets setup guide created: github-secrets-setup.md"
echo ""
echo "📋 Summary:"
echo "  1. Add the AWS credentials to GitHub repository secrets"
echo "  2. Add Apple certificate/profile (base64) to GitHub repository secrets" 
echo "  3. Update AWS Secrets Manager with real Apple/OpenRouter credentials"
echo "  4. Review the generated file: github-secrets-setup.md"
echo ""
echo "🚀 Ready to test! Push to main branch to trigger the pipeline."
