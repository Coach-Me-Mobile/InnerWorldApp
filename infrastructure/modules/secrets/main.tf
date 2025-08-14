# ==============================================================================
# SECRETS MANAGER MODULE
# ==============================================================================
# AWS Secrets Manager configuration for InnerWorldApp
# Manages API keys, credentials, and sensitive configuration
# ==============================================================================

# ==============================================================================
# OPENAI/OPENROUTER API KEY
# ==============================================================================

resource "aws_secretsmanager_secret" "openai_api_key" {
  name        = "${var.name_prefix}/openai/api-key"
  description = "OpenAI/OpenRouter API key for LLM and embeddings"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-openai-api-key"
    Type        = "APIKey"
    Service     = "OpenAI"
    Sensitivity = "High"
  })
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id = aws_secretsmanager_secret.openai_api_key.id
  secret_string = jsonencode({
    api_key        = var.openai_api_key != "" ? var.openai_api_key : "REPLACE_WITH_ACTUAL_KEY"
    provider       = "openrouter"
    base_url       = "https://openrouter.ai/api/v1"
    model_primary  = "anthropic/claude-3.5-sonnet"
    model_fallback = "openai/gpt-4"
    created_at     = timestamp()
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ==============================================================================
# NEPTUNE CONFIGURATION
# ==============================================================================

resource "aws_secretsmanager_secret" "neptune_config" {
  name        = "${var.name_prefix}/neptune/config"
  description = "Neptune graph database configuration for GraphRAG"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-neptune-config"
    Type        = "DatabaseConfiguration"
    Service     = "Neptune"
    Sensitivity = "Medium"
  })
}

resource "aws_secretsmanager_secret_version" "neptune_config" {
  secret_id = aws_secretsmanager_secret.neptune_config.id
  secret_string = jsonencode({
    # These will be populated by Terraform outputs after Neptune creation
    cluster_endpoint = "POPULATED_BY_TERRAFORM"
    reader_endpoint  = "POPULATED_BY_TERRAFORM"
    port             = "8182"
    iam_auth_enabled = "true"
    ssl_enabled      = "true"
    created_at       = timestamp()
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ==============================================================================
# APPLE SIGN-IN CONFIGURATION
# ==============================================================================

resource "aws_secretsmanager_secret" "apple_signin_key" {
  name        = "${var.name_prefix}/apple/signin-key"
  description = "Apple Sign-In private key and configuration"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-apple-signin-key"
    Type        = "AuthenticationKey"
    Service     = "Apple"
    Sensitivity = "High"
  })
}

resource "aws_secretsmanager_secret_version" "apple_signin_key" {
  secret_id = aws_secretsmanager_secret.apple_signin_key.id
  secret_string = jsonencode({
    team_id     = var.apple_team_id != "" ? var.apple_team_id : "REPLACE_WITH_TEAM_ID"
    key_id      = var.apple_key_id != "" ? var.apple_key_id : "REPLACE_WITH_KEY_ID"
    private_key = var.apple_private_key != "" ? var.apple_private_key : "REPLACE_WITH_PRIVATE_KEY"
    client_id   = var.apple_client_id != "" ? var.apple_client_id : "REPLACE_WITH_CLIENT_ID"
    created_at  = timestamp()
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ==============================================================================
# APP STORE CONNECT API KEY
# ==============================================================================

resource "aws_secretsmanager_secret" "app_store_connect_key" {
  name        = "${var.name_prefix}/appstoreconnect/api-key"
  description = "App Store Connect API key for TestFlight and App Store management"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-appstoreconnect-api-key"
    Type        = "APIKey"
    Service     = "AppStoreConnect"
    Sensitivity = "High"
  })
}

resource "aws_secretsmanager_secret_version" "app_store_connect_key" {
  secret_id = aws_secretsmanager_secret.app_store_connect_key.id
  secret_string = jsonencode({
    issuer_id   = var.app_store_connect_issuer_id != "" ? var.app_store_connect_issuer_id : "REPLACE_WITH_ISSUER_ID"
    key_id      = var.app_store_connect_key_id != "" ? var.app_store_connect_key_id : "REPLACE_WITH_KEY_ID"
    private_key = var.app_store_connect_private_key != "" ? var.app_store_connect_private_key : "REPLACE_WITH_PRIVATE_KEY"
    app_id      = var.app_store_connect_app_id != "" ? var.app_store_connect_app_id : "REPLACE_WITH_APP_ID"
    bundle_id   = var.apple_client_id != "" ? var.apple_client_id : "com.gauntletai.innerworld"
    created_at  = timestamp()
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ==============================================================================
# JWT SECRET FOR TOKEN SIGNING
# ==============================================================================

resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${var.name_prefix}/jwt/secret"
  description = "JWT secret key for token signing and verification"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-jwt-secret"
    Type        = "TokenSecret"
    Service     = "JWT"
    Sensitivity = "High"
  })
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    secret     = random_password.jwt_secret.result
    algorithm  = "HS256"
    expiry     = "24h"
    created_at = timestamp()
  })
}

# ==============================================================================
# WEBHOOK SECRETS
# ==============================================================================

resource "random_password" "webhook_secret" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "webhook_secret" {
  name        = "${var.name_prefix}/webhook/secret"
  description = "Webhook secret for validating incoming webhooks"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-webhook-secret"
    Type        = "WebhookSecret"
    Service     = "Webhooks"
    Sensitivity = "Medium"
  })
}

resource "aws_secretsmanager_secret_version" "webhook_secret" {
  secret_id = aws_secretsmanager_secret.webhook_secret.id
  secret_string = jsonencode({
    secret     = random_password.webhook_secret.result
    created_at = timestamp()
  })
}

# ==============================================================================
# ENCRYPTION KEYS FOR DATA PROTECTION
# ==============================================================================

resource "random_password" "encryption_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "encryption_key" {
  name        = "${var.name_prefix}/encryption/key"
  description = "Encryption key for sensitive data protection"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-encryption-key"
    Type        = "EncryptionKey"
    Service     = "DataProtection"
    Sensitivity = "High"
  })
}

resource "aws_secretsmanager_secret_version" "encryption_key" {
  secret_id = aws_secretsmanager_secret.encryption_key.id
  secret_string = jsonencode({
    key        = random_password.encryption_key.result
    algorithm  = "AES-256"
    created_at = timestamp()
  })
}

# ==============================================================================
# DATABASE SESSION KEY
# ==============================================================================

resource "random_password" "session_key" {
  length  = 48
  special = true
}

resource "aws_secretsmanager_secret" "session_key" {
  name        = "${var.name_prefix}/session/key"
  description = "Session encryption key for user sessions"

  recovery_window_in_days = var.recovery_window_days

  replica {
    region = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-session-key"
    Type        = "SessionKey"
    Service     = "SessionManagement"
    Sensitivity = "High"
  })
}

resource "aws_secretsmanager_secret_version" "session_key" {
  secret_id = aws_secretsmanager_secret.session_key.id
  secret_string = jsonencode({
    key        = random_password.session_key.result
    created_at = timestamp()
  })
}

# ==============================================================================
# IAM POLICY FOR LAMBDA ACCESS TO SECRETS
# ==============================================================================

data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      aws_secretsmanager_secret.openai_api_key.arn,
      aws_secretsmanager_secret.neptune_config.arn,
      aws_secretsmanager_secret.apple_signin_key.arn,
      aws_secretsmanager_secret.jwt_secret.arn,
      aws_secretsmanager_secret.webhook_secret.arn,
      aws_secretsmanager_secret.encryption_key.arn,
      aws_secretsmanager_secret.session_key.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "secretsmanager:ResourceTag/Project"
      values   = [var.project_name]
    }
  }
}

resource "aws_iam_policy" "secrets_access" {
  name_prefix = "${var.name_prefix}-secrets-access-"
  description = "IAM policy for Lambda functions to access Secrets Manager"
  policy      = data.aws_iam_policy_document.secrets_access.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-secrets-access-policy"
    Type = "IAMPolicy"
  })
}

# ==============================================================================
# SECRETS ROTATION CONFIGURATION
# ==============================================================================

# Lambda function for automatic secret rotation (optional)
resource "aws_lambda_function" "rotate_secrets" {
  count = var.enable_secret_rotation ? 1 : 0

  filename         = "${path.module}/rotate_secrets.zip"
  function_name    = "${var.name_prefix}-rotate-secrets"
  role             = aws_iam_role.rotation_lambda_role[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.rotate_secrets_zip[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rotate-secrets-lambda"
    Type = "LambdaFunction"
  })
}

# IAM role for rotation Lambda
resource "aws_iam_role" "rotation_lambda_role" {
  count = var.enable_secret_rotation ? 1 : 0

  name_prefix = "${var.name_prefix}-rotation-lambda-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rotation-lambda-role"
    Type = "IAMRole"
  })
}

# Create rotation Lambda ZIP file
data "archive_file" "rotate_secrets_zip" {
  count = var.enable_secret_rotation ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/rotate_secrets.zip"

  source {
    content = templatefile("${path.module}/rotate_secrets.py", {
      project_name = var.project_name
    })
    filename = "index.py"
  }
}
