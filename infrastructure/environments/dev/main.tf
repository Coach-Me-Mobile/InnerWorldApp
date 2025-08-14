# ==============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# ==============================================================================
# Minimal development environment for InnerWorld TestFlight deployment
# Optimized for cost and simplicity - just Cognito authentication
# ==============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # No backend configuration for dev - using local state
  # Uncomment for remote state after initial testing
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

  # Networking - minimal single-AZ for cost optimization
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = false # No NAT gateway for minimal setup
  single_nat_gateway = true

  # Cognito configuration - simplified for testing
  cognito_config = {
    enable_apple_signin               = false # Disable for initial testing
    enable_email_signin               = true
    password_policy_min_length        = 8    # Simpler for testing
    password_policy_require_uppercase = true
    password_policy_require_lowercase = true
    password_policy_require_numbers   = true
    password_policy_require_symbols   = false # Simpler for testing
    mfa_configuration                 = "OFF" # Disabled for testing
    email_verification_required       = true
    phone_verification_required       = false
  }

  # Secrets configuration - minimal
  secrets_config = {
    recovery_window_days = 7  # Minimum for dev
    replica_regions      = [] # No replication for dev
  }

  # Monitoring and logging - minimal
  enable_cloudwatch_logs = true
  log_retention_days     = 7 # Short retention for dev
  enable_vpc_flow_logs   = false

  # Features - disabled for minimal setup
  enable_codepipeline = false # Using GitHub Actions instead
  enable_xray_tracing = false # Disabled for dev

  # Backup configuration - minimal
  backup_config = {
    enable_backups        = false # Disabled for dev
    backup_retention_days = 7
    backup_schedule       = "cron(0 2 * * ? *)"
  }

  # Cost optimization - maximum savings for dev
  cost_optimization = {
    use_spot_instances                      = false
    enable_auto_scaling                     = false
    schedule_lambda_provisioned_concurrency = false
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "infrastructure_summary" {
  description = "Summary of development infrastructure"
  value       = module.infrastructure.infrastructure_summary
}

output "vpc_info" {
  description = "VPC information"
  value       = module.infrastructure.vpc
}

output "cognito_info" {
  description = "Cognito configuration for iOS app"
  value = {
    user_pool_id        = module.infrastructure.cognito.user_pool_id
    user_pool_client_id = module.infrastructure.cognito.user_pool_client_id
    identity_pool_id    = module.infrastructure.cognito.identity_pool_id
    user_pool_domain    = module.infrastructure.cognito.user_pool_domain
    user_pool_endpoint  = module.infrastructure.cognito_urls.user_pool_endpoint
    jwks_uri           = module.infrastructure.cognito_urls.jwks_uri
  }
  sensitive = false
}

output "secrets_info" {
  description = "Secrets Manager ARNs"
  value = {
    apple_signin_key_arn = module.infrastructure.secrets.apple_signin_key_arn
    jwt_secret_arn       = module.infrastructure.secrets.jwt_secret_arn
  }
  sensitive = false
}
