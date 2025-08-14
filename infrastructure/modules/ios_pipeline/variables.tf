# ==============================================================================
# VARIABLES FOR IOS PIPELINE MODULE
# ==============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# GITHUB CONFIGURATION
# ==============================================================================

variable "github_connection_arn" {
  description = "ARN of the GitHub CodeStar connection"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to monitor"
  type        = string
  default     = "main"
}

# ==============================================================================
# S3 BUCKET CONFIGURATION
# ==============================================================================

variable "testflight_builds_bucket_name" {
  description = "Name of the S3 bucket for TestFlight builds"
  type        = string
}

variable "testflight_builds_bucket_arn" {
  description = "ARN of the S3 bucket for TestFlight builds"
  type        = string
}

# ==============================================================================
# SECRETS CONFIGURATION
# ==============================================================================

variable "apple_developer_secrets_arn" {
  description = "ARN of AWS Secrets Manager secret containing Apple Developer credentials"
  type        = string
}

variable "app_store_connect_secrets_arn" {
  description = "ARN of AWS Secrets Manager secret containing App Store Connect API credentials"
  type        = string
}

# ==============================================================================
# PIPELINE CONFIGURATION
# ==============================================================================

variable "require_manual_approval" {
  description = "Require manual approval before TestFlight deployment"
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

variable "alarm_actions" {
  description = "List of SNS topic ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# ==============================================================================
# BUILD CONFIGURATION
# ==============================================================================

variable "enable_cache" {
  description = "Enable build caching for faster builds"
  type        = bool
  default     = true
}

variable "build_timeout_minutes" {
  description = "Timeout for build jobs in minutes"
  type        = number
  default     = 60

  validation {
    condition     = var.build_timeout_minutes >= 5 && var.build_timeout_minutes <= 480
    error_message = "Build timeout must be between 5 and 480 minutes."
  }
}

variable "test_timeout_minutes" {
  description = "Timeout for test jobs in minutes"
  type        = number
  default     = 30

  validation {
    condition     = var.test_timeout_minutes >= 5 && var.test_timeout_minutes <= 480
    error_message = "Test timeout must be between 5 and 480 minutes."
  }
}

variable "deploy_timeout_minutes" {
  description = "Timeout for deployment jobs in minutes"
  type        = number
  default     = 20

  validation {
    condition     = var.deploy_timeout_minutes >= 5 && var.deploy_timeout_minutes <= 480
    error_message = "Deploy timeout must be between 5 and 480 minutes."
  }
}
