# ==============================================================================
# COGNITO MODULE VARIABLES
# ==============================================================================
# Input variables for the Cognito module
# ==============================================================================

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# AUTHENTICATION CONFIGURATION
# ==============================================================================

variable "enable_apple_signin" {
  description = "Enable Apple Sign-In integration"
  type        = bool
  default     = true
}

variable "enable_email_signin" {
  description = "Enable email/password sign-in"
  type        = bool
  default     = true
}

variable "email_verification_required" {
  description = "Require email verification for new users"
  type        = bool
  default     = true
}

variable "phone_verification_required" {
  description = "Require phone verification for new users"
  type        = bool
  default     = false
}

# ==============================================================================
# PASSWORD POLICY
# ==============================================================================

variable "password_policy_min_length" {
  description = "Minimum password length"
  type        = number
  default     = 12
  
  validation {
    condition     = var.password_policy_min_length >= 8 && var.password_policy_min_length <= 128
    error_message = "Password minimum length must be between 8 and 128 characters."
  }
}

variable "password_policy_require_uppercase" {
  description = "Require uppercase letters in password"
  type        = bool
  default     = true
}

variable "password_policy_require_lowercase" {
  description = "Require lowercase letters in password"
  type        = bool
  default     = true
}

variable "password_policy_require_numbers" {
  description = "Require numbers in password"
  type        = bool
  default     = true
}

variable "password_policy_require_symbols" {
  description = "Require symbols in password"
  type        = bool
  default     = true
}

# ==============================================================================
# MFA CONFIGURATION
# ==============================================================================

variable "mfa_configuration" {
  description = "MFA configuration (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OPTIONAL"
  
  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "MFA configuration must be one of: OFF, ON, OPTIONAL."
  }
}

# ==============================================================================
# APPLE SIGN-IN CONFIGURATION
# ==============================================================================

variable "apple_team_id" {
  description = "Apple Developer Team ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_key_id" {
  description = "Apple Sign-In Key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_private_key" {
  description = "Apple Sign-In Private Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_client_id" {
  description = "Apple Sign-In Client ID (Bundle ID)"
  type        = string
  default     = ""
  sensitive   = true
}

# ==============================================================================
# LAMBDA TRIGGERS
# ==============================================================================

variable "enable_lambda_triggers" {
  description = "Enable Lambda triggers for Cognito events"
  type        = bool
  default     = false
}

# ==============================================================================
# DOMAIN CONFIGURATION
# ==============================================================================

variable "custom_domain" {
  description = "Custom domain for Cognito hosted UI (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = ""
}
