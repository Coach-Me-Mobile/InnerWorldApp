# ==============================================================================
# SECRETS MODULE OUTPUTS
# ==============================================================================
# Output values from the secrets module
# ==============================================================================

# Secret ARNs for reference by other modules
output "openai_api_key_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.arn
  sensitive   = false
}

output "neo4j_credentials_arn" {
  description = "ARN of the Neo4j credentials secret"
  value       = aws_secretsmanager_secret.neo4j_credentials.arn
  sensitive   = false
}

output "apple_signin_key_arn" {
  description = "ARN of the Apple Sign-In key secret"
  value       = aws_secretsmanager_secret.apple_signin_key.arn
  sensitive   = false
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
  sensitive   = false
}

output "webhook_secret_arn" {
  description = "ARN of the webhook secret"
  value       = aws_secretsmanager_secret.webhook_secret.arn
  sensitive   = false
}

output "encryption_key_arn" {
  description = "ARN of the encryption key secret"
  value       = aws_secretsmanager_secret.encryption_key.arn
  sensitive   = false
}

output "session_key_arn" {
  description = "ARN of the session key secret"
  value       = aws_secretsmanager_secret.session_key.arn
  sensitive   = false
}

# Secret Names for reference
output "openai_api_key_name" {
  description = "Name of the OpenAI API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.name
  sensitive   = false
}

output "neo4j_credentials_name" {
  description = "Name of the Neo4j credentials secret"
  value       = aws_secretsmanager_secret.neo4j_credentials.name
  sensitive   = false
}

output "apple_signin_key_name" {
  description = "Name of the Apple Sign-In key secret"
  value       = aws_secretsmanager_secret.apple_signin_key.name
  sensitive   = false
}

output "jwt_secret_name" {
  description = "Name of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.name
  sensitive   = false
}

output "webhook_secret_name" {
  description = "Name of the webhook secret"
  value       = aws_secretsmanager_secret.webhook_secret.name
  sensitive   = false
}

output "encryption_key_name" {
  description = "Name of the encryption key secret"
  value       = aws_secretsmanager_secret.encryption_key.name
  sensitive   = false
}

output "session_key_name" {
  description = "Name of the session key secret"
  value       = aws_secretsmanager_secret.session_key.name
  sensitive   = false
}

# IAM Policy for Lambda access
output "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for Lambda to access secrets"
  value       = aws_iam_policy.secrets_access.arn
  sensitive   = false
}

output "secrets_access_policy_name" {
  description = "Name of the IAM policy for Lambda to access secrets"
  value       = aws_iam_policy.secrets_access.name
  sensitive   = false
}

# Rotation Lambda (if enabled)
output "rotation_lambda_arn" {
  description = "ARN of the secrets rotation Lambda function"
  value       = var.enable_secret_rotation ? aws_lambda_function.rotate_secrets[0].arn : null
  sensitive   = false
}

output "rotation_lambda_role_arn" {
  description = "ARN of the secrets rotation Lambda role"
  value       = var.enable_secret_rotation ? aws_iam_role.rotation_lambda_role[0].arn : null
  sensitive   = false
}

# All secret ARNs for convenience
output "all_secret_arns" {
  description = "Map of all secret ARNs"
  value = {
    openai_api_key    = aws_secretsmanager_secret.openai_api_key.arn
    neo4j_credentials = aws_secretsmanager_secret.neo4j_credentials.arn
    apple_signin_key  = aws_secretsmanager_secret.apple_signin_key.arn
    jwt_secret        = aws_secretsmanager_secret.jwt_secret.arn
    webhook_secret    = aws_secretsmanager_secret.webhook_secret.arn
    encryption_key    = aws_secretsmanager_secret.encryption_key.arn
    session_key       = aws_secretsmanager_secret.session_key.arn
  }
  sensitive = false
}

# All secret names for convenience
output "all_secret_names" {
  description = "Map of all secret names"
  value = {
    openai_api_key    = aws_secretsmanager_secret.openai_api_key.name
    neo4j_credentials = aws_secretsmanager_secret.neo4j_credentials.name
    apple_signin_key  = aws_secretsmanager_secret.apple_signin_key.name
    jwt_secret        = aws_secretsmanager_secret.jwt_secret.name
    webhook_secret    = aws_secretsmanager_secret.webhook_secret.name
    encryption_key    = aws_secretsmanager_secret.encryption_key.name
    session_key       = aws_secretsmanager_secret.session_key.name
  }
  sensitive = false
}
