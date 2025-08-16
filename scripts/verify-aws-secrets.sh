#!/bin/bash
# ==============================================================================
# AWS SECRETS VERIFICATION SCRIPT
# ==============================================================================
# Verifies and helps update AWS Secrets Manager configuration for iOS CI/CD
# Run this to check if your secrets are properly configured
# ==============================================================================

set -e

PROJECT_NAME="innerworld"
ENVIRONMENT="prod"
REGION="us-east-1"

echo "🔍 Verifying AWS Secrets Manager Configuration"
echo "=============================================="
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"  
echo "Region: $REGION"
echo ""

# Check AWS credentials
echo "🔧 Checking AWS Configuration..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: $ACCOUNT_ID"
echo "✅ AWS Region: $REGION"
echo ""

# Function to check a secret
check_secret() {
    local secret_name="$1"
    local description="$2"
    
    echo "📋 Checking: $description"
    echo "   Secret: $secret_name"
    
    if secret_value=$(aws secretsmanager get-secret-value \
        --secret-id "$secret_name" \
        --region "$REGION" \
        --query SecretString --output text 2>/dev/null); then
        
        echo "   Status: ✅ Secret exists"
        
        # Check for placeholder values (without exposing actual values)
        if echo "$secret_value" | grep -q "REPLACE_WITH\|YOUR_"; then
            echo "   Value: ⚠️  Contains placeholder values - needs manual update"
            placeholder_count=$(echo "$secret_value" | jq -r 'to_entries[] | select(.value | type == "string" and (contains("REPLACE_WITH") or contains("YOUR_"))) | .key' 2>/dev/null | wc -l)
            echo "     Found $placeholder_count placeholder field(s)"
        else
            echo "   Value: ✅ Appears to be configured with real values"
            # Show only non-sensitive metadata
            field_count=$(echo "$secret_value" | jq 'keys | length' 2>/dev/null || echo "unknown")
            echo "     Contains $field_count configuration field(s)"
        fi
    else
        echo "   Status: ❌ Secret not found or no access"
    fi
    echo ""
}

# Check all required secrets
echo "🔐 Checking Required Secrets..."
echo ""

check_secret "$PROJECT_NAME-$ENVIRONMENT/apple/signin-key" "Apple Sign-In Key"
check_secret "$PROJECT_NAME-$ENVIRONMENT/appstoreconnect/api-key" "App Store Connect API Key"  
check_secret "$PROJECT_NAME-$ENVIRONMENT/openrouter/api-key" "OpenRouter API Key"

echo "📋 Summary & Next Steps"
echo "======================="
echo ""
echo "If you see placeholder values above, update them manually:"
echo ""
echo "1. 📱 Apple Sign-In Key:"
echo "   aws secretsmanager update-secret \\"
echo "     --region $REGION \\"
echo "     --secret-id '$PROJECT_NAME-$ENVIRONMENT/apple/signin-key' \\"
echo "     --secret-string '{"
echo "       \"team_id\": \"YOUR_APPLE_TEAM_ID\","
echo "       \"key_id\": \"YOUR_APPLE_KEY_ID\","  
echo "       \"private_key\": \"-----BEGIN PRIVATE KEY-----\\nYOUR_PRIVATE_KEY\\n-----END PRIVATE KEY-----\","
echo "       \"client_id\": \"com.thoughtmanifold.InnerWorld\""
echo "     }'"
echo ""
echo "2. 🏪 App Store Connect API Key:"
echo "   aws secretsmanager update-secret \\"
echo "     --region $REGION \\"
echo "     --secret-id '$PROJECT_NAME-$ENVIRONMENT/appstoreconnect/api-key' \\"
echo "     --secret-string '{"
echo "       \"issuer_id\": \"YOUR_ASC_ISSUER_ID\","
echo "       \"key_id\": \"YOUR_ASC_KEY_ID\","
echo "       \"private_key\": \"-----BEGIN PRIVATE KEY-----\\nYOUR_ASC_PRIVATE_KEY\\n-----END PRIVATE KEY-----\","
echo "       \"bundle_id\": \"com.thoughtmanifold.InnerWorld\""
echo "     }'"
echo ""
echo "3. 🤖 OpenRouter API Key (for backend LLM):"
echo "   aws secretsmanager update-secret \\"
echo "     --region $REGION \\"
echo "     --secret-id '$PROJECT_NAME-$ENVIRONMENT/openrouter/api-key' \\"
echo "     --secret-string '{"
echo "       \"api_key\": \"sk-or-v1-YOUR-OPENROUTER-KEY\","
echo "       \"provider\": \"openrouter\","
echo "       \"base_url\": \"https://openrouter.ai/api/v1\","
echo "       \"model_primary\": \"anthropic/claude-3.5-sonnet\","
echo "       \"model_fallback\": \"openai/gpt-4\""
echo "     }'"
echo ""
echo "📖 For detailed setup instructions, see:"
echo "   docs/MANUAL_DEPLOYMENT_GUIDE.md"
echo ""
echo "🧪 To test your iOS CI/CD pipeline:"
echo "   git push origin main"
echo "   # Or manually trigger: gh workflow run 'iOS CI/CD'"
