# ==============================================================================
# LAMBDA MODULE VARIABLES
# ==============================================================================
# Input variables for the Lambda module
# ==============================================================================

# ==============================================================================
# GENERAL CONFIGURATION
# ==============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
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
# NETWORKING CONFIGURATION
# ==============================================================================

variable "vpc_id" {
  description = "VPC ID where Lambda functions will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Lambda functions"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  type        = string
}

# ==============================================================================
# LAMBDA CONFIGURATION
# ==============================================================================

variable "conversation_handler_zip" {
  description = "Path to conversation handler zip file"
  type        = string
  default     = "../../backend/bin/conversation-handler.zip"
}

variable "health_check_zip" {
  description = "Path to health check zip file"  
  type        = string
  default     = "../../backend/bin/health-check.zip"
}

variable "lambda_environment_variables" {
  description = "Environment variables for Lambda functions"
  type        = map(string)
  default     = {
    ENVIRONMENT = "development"
    DEBUG       = "true"
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for Lambda functions"
  type        = bool
  default     = false
}

# ==============================================================================
# SECRETS AND PERMISSIONS
# ==============================================================================

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs that Lambda functions can access"
  type        = list(string)
}

# ==============================================================================
# API GATEWAY CONFIGURATION
# ==============================================================================

variable "enable_cors" {
  description = "Enable CORS for REST API Gateway"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_headers" {
  description = "Allowed headers for CORS"
  type        = list(string)
  default     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
}

variable "cors_allowed_methods" {
  description = "Allowed methods for CORS"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
}
