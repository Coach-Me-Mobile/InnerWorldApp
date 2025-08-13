# ==============================================================================
# SECRETS MODULE OUTPUTS
# ==============================================================================
# Output values for the secrets module
# ==============================================================================

# ==============================================================================
# SECRET ARNS
# ==============================================================================

output "openai_api_key_arn" {
  description = "ARN of the OpenAI/OpenRouter API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "neptune_config_arn" {
  description = "ARN of the Neptune configuration secret"
  value       = aws_secretsmanager_secret.neptune_config.arn
}

output "apple_signin_key_arn" {
  description = "ARN of the Apple Sign-In key secret"
  value       = aws_secretsmanager_secret.apple_signin_key.arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "webhook_secret_arn" {
  description = "ARN of the webhook secret"
  value       = aws_secretsmanager_secret.webhook_secret.arn
}

output "encryption_key_arn" {
  description = "ARN of the encryption key secret"
  value       = aws_secretsmanager_secret.encryption_key.arn
}

output "session_key_arn" {
  description = "ARN of the session key secret"
  value       = aws_secretsmanager_secret.session_key.arn
}

# ==============================================================================
# SECRET NAMES
# ==============================================================================

output "openai_api_key_name" {
  description = "Name of the OpenAI/OpenRouter API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.name
}

output "neptune_config_name" {
  description = "Name of the Neptune configuration secret"
  value       = aws_secretsmanager_secret.neptune_config.name
}

output "apple_signin_key_name" {
  description = "Name of the Apple Sign-In key secret"
  value       = aws_secretsmanager_secret.apple_signin_key.name
}

output "jwt_secret_name" {
  description = "Name of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.name
}

# ==============================================================================
# IAM POLICY OUTPUT
# ==============================================================================

output "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for accessing secrets"
  value       = aws_iam_policy.secrets_access.arn
}

# ==============================================================================
# SUMMARY OUTPUT
# ==============================================================================

output "secrets_summary" {
  description = "Summary of all secrets created"
  value = {
    openai_api_key = {
      arn  = aws_secretsmanager_secret.openai_api_key.arn
      name = aws_secretsmanager_secret.openai_api_key.name
    }
    neptune_config = {
      arn  = aws_secretsmanager_secret.neptune_config.arn
      name = aws_secretsmanager_secret.neptune_config.name
    }
    apple_signin_key = {
      arn  = aws_secretsmanager_secret.apple_signin_key.arn
      name = aws_secretsmanager_secret.apple_signin_key.name
    }
    jwt_secret = {
      arn  = aws_secretsmanager_secret.jwt_secret.arn
      name = aws_secretsmanager_secret.jwt_secret.name
    }
  }
}