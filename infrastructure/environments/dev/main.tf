# ==============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# ==============================================================================
# Terraform configuration for the development environment
# This file uses the main infrastructure modules with dev-specific settings
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for dev environment
  # This will be uncommented after the S3 bucket is created
  # backend "s3" {
  #   bucket         = "innerworld-dev-terraform-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "innerworld-dev-terraform-locks"
  #   encrypt        = true
  # }
}

# ==============================================================================
# DEVELOPMENT CONFIGURATION
# ==============================================================================

module "infrastructure" {
  source = "../../"
  
  # Project configuration
  project_name = "innerworld"
  environment  = "dev"
  aws_region   = "us-east-1"
  
  # Networking - optimized for cost in dev
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = true
  single_nat_gateway = true  # Single NAT for cost savings in dev
  
  # Cognito configuration
  cognito_config = {
    enable_apple_signin           = false  # Disable for dev to avoid Apple Developer requirements
    enable_email_signin          = true
    password_policy_min_length   = 8      # Relaxed for dev
    password_policy_require_uppercase = false
    password_policy_require_lowercase = true
    password_policy_require_numbers  = true
    password_policy_require_symbols  = false
    mfa_configuration            = "OFF"  # Disabled for dev ease
    email_verification_required = false   # Disabled for dev ease
    phone_verification_required = false
  }
  
  # Secrets configuration
  secrets_config = {
    recovery_window_days = 7  # Minimum for dev
    replica_regions     = []  # No replication for dev
  }
  
  # Monitoring and logging
  enable_cloudwatch_logs = true
  log_retention_days    = 7    # Short retention for dev
  enable_vpc_flow_logs  = false # Disabled for cost savings
  enable_guardduty      = false # Disabled for cost savings
  
  # Features
  enable_codepipeline = false  # Enable once GitHub connection is set up
  enable_xray_tracing = false
  
  # Backup configuration
  backup_config = {
    enable_backups        = false  # Disabled for dev
    backup_retention_days = 7
    backup_schedule       = "cron(0 2 * * ? *)"
  }
  
  # Cost optimization for dev
  cost_optimization = {
    use_spot_instances = false  # Keep false for stability
    enable_auto_scaling = false
    schedule_lambda_provisioned_concurrency = false
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "infrastructure_summary" {
  description = "Summary of development infrastructure"
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

output "backend_config" {
  description = "Backend configuration for remote state"
  value = module.infrastructure.backend_config
}
