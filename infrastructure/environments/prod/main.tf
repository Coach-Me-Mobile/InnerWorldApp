# ==============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# ==============================================================================
# Terraform configuration for the production environment
# This file uses the main infrastructure modules with production-grade settings
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for production environment
  # This will be uncommented after the S3 bucket is created
  # backend "s3" {
  #   bucket         = "innerworld-prod-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "innerworld-prod-terraform-locks"
  #   encrypt        = true
  # }
}

# ==============================================================================
# PRODUCTION CONFIGURATION
# ==============================================================================

module "infrastructure" {
  source = "../../"
  
  # Project configuration
  project_name = "innerworld"
  environment  = "prod"
  aws_region   = "us-east-1"
  
  # Networking - full production setup
  vpc_cidr           = "10.2.0.0/16"
  enable_nat_gateway = true
  single_nat_gateway = false  # Multi-AZ for high availability
  
  # Cognito configuration - strict production settings
  cognito_config = {
    enable_apple_signin           = true
    enable_email_signin          = true
    password_policy_min_length   = 12
    password_policy_require_uppercase = true
    password_policy_require_lowercase = true
    password_policy_require_numbers  = true
    password_policy_require_symbols  = true
    mfa_configuration            = "OPTIONAL"  # User choice for teens
    email_verification_required = true
    phone_verification_required = false
  }
  
  # Secrets configuration - with replication
  secrets_config = {
    recovery_window_days = 30  # Maximum for production
    replica_regions     = ["us-west-2", "eu-west-1"]  # Multi-region for DR
  }
  
  # Monitoring and logging - full production monitoring
  enable_cloudwatch_logs = true
  log_retention_days    = 30   # Extended retention for production
  enable_vpc_flow_logs  = true
  enable_guardduty      = true # Security monitoring for production
  
  # Features - all enabled for production
  enable_codepipeline = true
  enable_xray_tracing = true   # Full tracing for production debugging
  
  # Backup configuration - comprehensive backup strategy
  backup_config = {
    enable_backups        = true
    backup_retention_days = 90  # Extended retention for production
    backup_schedule       = "cron(0 2 * * ? *)"  # Daily backups
  }
  
  # Production optimization
  cost_optimization = {
    use_spot_instances = false  # Reliability over cost for production
    enable_auto_scaling = true
    schedule_lambda_provisioned_concurrency = true  # Performance optimization
  }
  
  # GitHub configuration (set these in terraform.tfvars)
  github_connection_arn = var.github_connection_arn
  github_repository     = var.github_repository
  github_branch         = "main"  # Use main branch for production
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
  description = "Summary of production infrastructure"
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
