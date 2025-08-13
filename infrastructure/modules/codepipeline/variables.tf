# ==============================================================================
# CODEPIPELINE MODULE VARIABLES
# ==============================================================================
# Input variables for the CodePipeline module
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
  default     = "GauntletAI/InnerWorldApp"
}

variable "github_branch" {
  description = "GitHub branch to monitor"
  type        = string
  default     = "main"
}

# ==============================================================================
# BUILD CONFIGURATION
# ==============================================================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = ""
}

# ==============================================================================
# OPTIONAL FEATURES
# ==============================================================================

variable "enable_manual_approval" {
  description = "Enable manual approval step for production deployments"
  type        = bool
  default     = true
}

variable "enable_security_scan" {
  description = "Enable security scanning in pipeline"
  type        = bool
  default     = true
}

variable "enable_infrastructure_validation" {
  description = "Enable infrastructure validation in pipeline"
  type        = bool
  default     = true
}
