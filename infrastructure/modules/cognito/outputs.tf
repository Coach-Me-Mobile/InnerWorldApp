# ==============================================================================
# COGNITO MODULE OUTPUTS
# ==============================================================================
# Output values from the Cognito module
# ==============================================================================

# ==============================================================================
# USER POOL OUTPUTS
# ==============================================================================

output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
  sensitive   = false
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
  sensitive   = false
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
  sensitive   = false
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
  sensitive   = false
}

# ==============================================================================
# USER POOL CLIENT OUTPUTS
# ==============================================================================

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.ios_app.id
  sensitive   = false
}

output "user_pool_client_secret" {
  description = "Secret of the Cognito User Pool Client (if applicable)"
  value       = aws_cognito_user_pool_client.ios_app.client_secret
  sensitive   = true
}

# ==============================================================================
# IDENTITY POOL OUTPUTS
# ==============================================================================

output "identity_pool_id" {
  description = "ID of the Cognito Identity Pool"
  value       = aws_cognito_identity_pool.main.id
  sensitive   = false
}

output "identity_pool_arn" {
  description = "ARN of the Cognito Identity Pool"
  value       = aws_cognito_identity_pool.main.arn
  sensitive   = false
}

# ==============================================================================
# IAM ROLE OUTPUTS
# ==============================================================================

output "cognito_authenticated_role_arn" {
  description = "ARN of the Cognito authenticated IAM role"
  value       = aws_iam_role.authenticated.arn
  sensitive   = false
}

output "cognito_unauthenticated_role_arn" {
  description = "ARN of the Cognito unauthenticated IAM role"
  value       = aws_iam_role.unauthenticated.arn
  sensitive   = false
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role for Cognito triggers"
  value       = var.enable_lambda_triggers ? aws_iam_role.lambda_execution[0].arn : null
  sensitive   = false
}

# ==============================================================================
# AUTHENTICATION URLS
# ==============================================================================

output "login_url" {
  description = "Login URL for the Cognito hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.ios_app.id}&response_type=code&scope=openid+email+profile&redirect_uri=innerworld://auth/callback"
  sensitive   = false
}

output "logout_url" {
  description = "Logout URL for the Cognito hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/logout?client_id=${aws_cognito_user_pool_client.ios_app.id}&logout_uri=innerworld://auth/logout"
  sensitive   = false
}

output "signup_url" {
  description = "Sign-up URL for the Cognito hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/signup?client_id=${aws_cognito_user_pool_client.ios_app.id}&response_type=code&scope=openid+email+profile&redirect_uri=innerworld://auth/callback"
  sensitive   = false
}

output "forgot_password_url" {
  description = "Forgot password URL for the Cognito hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/forgotPassword?client_id=${aws_cognito_user_pool_client.ios_app.id}&response_type=code&scope=openid+email+profile&redirect_uri=innerworld://auth/callback"
  sensitive   = false
}

# ==============================================================================
# JWKS AND TOKEN ENDPOINTS
# ==============================================================================

output "jwks_uri" {
  description = "JWKS URI for token verification"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}/.well-known/jwks.json"
  sensitive   = false
}

output "token_endpoint" {
  description = "Token endpoint for OAuth flows"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"
  sensitive   = false
}

output "userinfo_endpoint" {
  description = "UserInfo endpoint for getting user information"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/userInfo"
  sensitive   = false
}

# ==============================================================================
# IDENTITY PROVIDER OUTPUTS
# ==============================================================================

output "apple_identity_provider_name" {
  description = "Name of the Apple identity provider"
  value       = var.enable_apple_signin ? aws_cognito_identity_provider.apple[0].provider_name : null
  sensitive   = false
}

# ==============================================================================
# LAMBDA TRIGGER OUTPUTS
# ==============================================================================

output "lambda_trigger_arns" {
  description = "ARNs of Lambda trigger functions"
  value = var.enable_lambda_triggers ? {
    pre_signup         = aws_lambda_function.pre_signup[0].arn
    post_confirmation  = aws_lambda_function.post_confirmation[0].arn
    pre_authentication = aws_lambda_function.pre_authentication[0].arn
    post_authentication = aws_lambda_function.post_authentication[0].arn
    custom_message     = aws_lambda_function.custom_message[0].arn
  } : null
  sensitive = false
}

# ==============================================================================
# CONFIGURATION SUMMARY
# ==============================================================================

output "cognito_config" {
  description = "Summary of Cognito configuration"
  value = {
    user_pool_id          = aws_cognito_user_pool.main.id
    identity_pool_id      = aws_cognito_identity_pool.main.id
    client_id            = aws_cognito_user_pool_client.ios_app.id
    domain               = aws_cognito_user_pool_domain.main.domain
    apple_signin_enabled = var.enable_apple_signin
    mfa_configuration    = var.mfa_configuration
    lambda_triggers_enabled = var.enable_lambda_triggers
    
    # Client configuration for iOS app
    ios_client_config = {
      user_pool_id     = aws_cognito_user_pool.main.id
      client_id        = aws_cognito_user_pool_client.ios_app.id
      identity_pool_id = aws_cognito_identity_pool.main.id
      region          = var.aws_region
      
      # OAuth configuration
      oauth_flows     = aws_cognito_user_pool_client.ios_app.allowed_oauth_flows
      oauth_scopes    = aws_cognito_user_pool_client.ios_app.allowed_oauth_scopes
      callback_urls   = aws_cognito_user_pool_client.ios_app.callback_urls
      logout_urls     = aws_cognito_user_pool_client.ios_app.logout_urls
      
      # Token configuration
      access_token_validity  = aws_cognito_user_pool_client.ios_app.access_token_validity
      id_token_validity     = aws_cognito_user_pool_client.ios_app.id_token_validity
      refresh_token_validity = aws_cognito_user_pool_client.ios_app.refresh_token_validity
    }
  }
  sensitive = false
}
