# ==============================================================================
# PRODUCTION ENVIRONMENT VARIABLES
# ==============================================================================
# Variables for the production environment
# These are passed through to the root module
# ==============================================================================

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "innerworld"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway"
  type        = bool
  default     = false
}

# ==============================================================================
# FEATURE FLAGS
# ==============================================================================

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention days"
  type        = number
  default     = 14
}

# ==============================================================================
# CONFIGURATION OBJECTS
# ==============================================================================

variable "cognito_config" {
  description = "Cognito configuration"
  type = object({
    enable_apple_signin               = bool
    enable_email_signin               = bool
    password_policy_min_length        = number
    password_policy_require_uppercase = bool
    password_policy_require_lowercase = bool
    password_policy_require_numbers   = bool
    password_policy_require_symbols   = bool
    mfa_configuration                 = string
    email_verification_required       = bool
    phone_verification_required       = bool
  })
  default = {
    enable_apple_signin               = true
    enable_email_signin               = true
    password_policy_min_length        = 12
    password_policy_require_uppercase = true
    password_policy_require_lowercase = true
    password_policy_require_numbers   = true
    password_policy_require_symbols   = true
    mfa_configuration                 = "OPTIONAL"
    email_verification_required       = true
    phone_verification_required       = false
  }
}

variable "secrets_config" {
  description = "Secrets Manager configuration"
  type = object({
    recovery_window_days = number
    replica_regions      = list(string)
  })
  default = {
    recovery_window_days = 7
    replica_regions      = []
  }
}

variable "backup_config" {
  description = "Backup configuration"
  type = object({
    enable_backups        = bool
    backup_retention_days = number
    backup_schedule       = string
  })
  default = {
    enable_backups        = true
    backup_retention_days = 30
    backup_schedule       = "cron(0 2 * * ? *)"
  }
}

variable "cost_optimization" {
  description = "Cost optimization settings"
  type = object({
    use_spot_instances                      = bool
    enable_auto_scaling                     = bool
    schedule_lambda_provisioned_concurrency = bool
  })
  default = {
    use_spot_instances                      = false
    enable_auto_scaling                     = true
    schedule_lambda_provisioned_concurrency = false
  }
}

variable "lambda_environment_variables" {
  description = "Additional Lambda environment variables"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# SECRETS (Sensitive)
# ==============================================================================

variable "openai_api_key" {
  description = "OpenRouter API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_team_id" {
  description = "Apple Developer Team ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_key_id" {
  description = "Apple Key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_private_key" {
  description = "Apple Private Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_client_id" {
  description = "Apple Client ID (Bundle ID)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_store_connect_issuer_id" {
  description = "App Store Connect Issuer ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_store_connect_key_id" {
  description = "App Store Connect Key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_store_connect_private_key" {
  description = "App Store Connect Private Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_store_connect_app_id" {
  description = "App Store Connect App ID"
  type        = string
  default     = ""
  sensitive   = true
}
