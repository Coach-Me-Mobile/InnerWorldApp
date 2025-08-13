# ==============================================================================
# STAGING ENVIRONMENT CONFIGURATION
# ==============================================================================
# Terraform configuration for the staging environment
# This file uses the main infrastructure modules with staging-specific settings
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for staging environment
  # This will be uncommented after the S3 bucket is created
  # backend "s3" {
  #   bucket         = "innerworld-staging-terraform-state"
  #   key            = "staging/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "innerworld-staging-terraform-locks"
  #   encrypt        = true
  # }
}

# ==============================================================================
# STAGING CONFIGURATION
# ==============================================================================

module "infrastructure" {
  source = "../../"
  
  # Project configuration
  project_name = "innerworld"
  environment  = "staging"
  aws_region   = "us-east-1"
  
  # Networking - production-like but cost-conscious
  vpc_cidr           = "10.1.0.0/16"
  enable_nat_gateway = true
  single_nat_gateway = false  # Multi-AZ for staging testing
  
  # Cognito configuration - production-like settings
  cognito_config = {
    enable_apple_signin           = true
    enable_email_signin          = true
    password_policy_min_length   = 12
    password_policy_require_uppercase = true
    password_policy_require_lowercase = true
    password_policy_require_numbers  = true
    password_policy_require_symbols  = true
    mfa_configuration            = "OPTIONAL"
    email_verification_required = true
    phone_verification_required = false
  }
  
  # Secrets configuration
  secrets_config = {
    recovery_window_days = 7
    replica_regions     = ["us-west-2"]  # Single replica for staging
  }
  
  # Monitoring and logging
  enable_cloudwatch_logs = true
  log_retention_days    = 14   # Moderate retention for staging
  enable_vpc_flow_logs  = true
  enable_guardduty      = false # Cost savings for staging
  
  # Features
  enable_codepipeline = true   # Full CI/CD for staging
  enable_xray_tracing = false
  
  # Backup configuration
  backup_config = {
    enable_backups        = true
    backup_retention_days = 14
    backup_schedule       = "cron(0 2 * * ? *)"
  }
  
  # Cost optimization for staging
  cost_optimization = {
    use_spot_instances = false
    enable_auto_scaling = true
    schedule_lambda_provisioned_concurrency = false
  }
  
  # GitHub configuration (set these in terraform.tfvars)
  github_connection_arn = var.github_connection_arn
  github_repository     = var.github_repository
  github_branch         = "staging"  # Use staging branch
}

# ==============================================================================
# VARIABLES
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

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "infrastructure_summary" {
  description = "Summary of staging infrastructure"
  value = module.infrastructure.infrastructure_summary
}

output "vpc_info" {
  description = "VPC information"
  value = module.infrastructure.vpc
}

output "cognito_info" {
  description = "Cognito configuration"
  value = module.infrastructure.cognito
}

output "secrets_info" {
  description = "Secrets Manager information"
  value = module.infrastructure.secrets
}

output "codepipeline_info" {
  description = "CodePipeline information"
  value = module.infrastructure.codepipeline
}

output "backend_config" {
  description = "Backend configuration for remote state"
  value = module.infrastructure.backend_config
}
