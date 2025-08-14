# ==============================================================================
# VARIABLES CONFIGURATION
# ==============================================================================
# Global variables for InnerWorldApp infrastructure
# These variables are used across all modules and environments
# ==============================================================================

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================

variable "project_name" {
  description = "Name of the project - used for resource naming and tagging"
  type        = string
  default     = "innerworld"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ==============================================================================
# AWS CONFIGURATION
# ==============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use (defaults to first 3 in region)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (recommended for prod)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization for dev)"
  type        = bool
  default     = false
}

# ==============================================================================
# COGNITO CONFIGURATION
# ==============================================================================

variable "cognito_config" {
  description = "Configuration for AWS Cognito User Pool"
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

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.cognito_config.mfa_configuration)
    error_message = "MFA configuration must be one of: OFF, ON, OPTIONAL."
  }

  validation {
    condition     = var.cognito_config.password_policy_min_length >= 8 && var.cognito_config.password_policy_min_length <= 128
    error_message = "Password minimum length must be between 8 and 128 characters."
  }
}

# ==============================================================================
# SECRETS MANAGER CONFIGURATION
# ==============================================================================

variable "secrets_config" {
  description = "Configuration for AWS Secrets Manager"
  type = object({
    recovery_window_days = number
    replica_regions      = list(string)
  })

  default = {
    recovery_window_days = 7
    replica_regions      = []
  }

  validation {
    condition     = var.secrets_config.recovery_window_days >= 7 && var.secrets_config.recovery_window_days <= 30
    error_message = "Secrets recovery window must be between 7 and 30 days."
  }
}

# ==============================================================================
# MONITORING AND LOGGING
# ==============================================================================

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for services"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# ==============================================================================
# SECURITY CONFIGURATION
# ==============================================================================

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}



# ==============================================================================
# BACKUP AND DISASTER RECOVERY
# ==============================================================================

variable "backup_config" {
  description = "Configuration for backup and disaster recovery"
  type = object({
    enable_backups        = bool
    backup_retention_days = number
    backup_schedule       = string
  })

  default = {
    enable_backups        = true
    backup_retention_days = 30
    backup_schedule       = "cron(0 2 * * ? *)" # Daily at 2 AM
  }

  validation {
    condition     = var.backup_config.backup_retention_days >= 1 && var.backup_config.backup_retention_days <= 365
    error_message = "Backup retention days must be between 1 and 365."
  }
}

# ==============================================================================
# FEATURE FLAGS
# ==============================================================================

variable "enable_codepipeline" {
  description = "Enable AWS CodePipeline for CI/CD (legacy)"
  type        = bool
  default     = false
}

variable "enable_ios_pipeline" {
  description = "Enable iOS CI/CD pipeline for TestFlight deployment"
  type        = bool
  default     = true
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for Lambda functions"
  type        = bool
  default     = false # Enable for debugging when needed
}

# ==============================================================================
# COST OPTIMIZATION
# ==============================================================================

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

# ==============================================================================
# CODEPIPELINE CONFIGURATION
# ==============================================================================

variable "github_connection_arn" {
  description = "ARN of the GitHub CodeStar connection (must be created manually)"
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "GauntletAI/InnerWorldApp"
}

variable "github_branch" {
  description = "GitHub branch to monitor"
  type        = string
  default     = "main"
}

# ==============================================================================
# LAMBDA CONFIGURATION
# ==============================================================================

variable "lambda_environment_variables" {
  description = "Additional environment variables for Lambda functions"
  type        = map(string)
  default     = {}
}
