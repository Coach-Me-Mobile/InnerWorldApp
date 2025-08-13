# ==============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# ==============================================================================
# Single production environment for InnerWorld MVP
# Optimized for teen safety, real-time conversations, and GraphRAG
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
  backend "s3" {
    bucket         = "innerworld-prod-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "innerworld-prod-terraform-locks"
    encrypt        = true
  }
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

  # Networking - production-grade, multi-AZ
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = true
  single_nat_gateway = false # Multi-AZ for high availability

  # Cognito configuration - strict for teen safety
  cognito_config = {
    enable_apple_signin               = true
    enable_email_signin               = true
    password_policy_min_length        = 12
    password_policy_require_uppercase = true
    password_policy_require_lowercase = true
    password_policy_require_numbers   = true
    password_policy_require_symbols   = true
    mfa_configuration                 = "OPTIONAL" # User choice for teens
    email_verification_required       = true
    phone_verification_required       = false
  }

  # Secrets configuration - with replication for DR
  secrets_config = {
    recovery_window_days = 30            # Maximum for production
    replica_regions      = ["us-west-2"] # Single replica for DR
  }

  # Monitoring and logging - comprehensive for production
  enable_cloudwatch_logs = true
  log_retention_days     = 30 # Extended retention for production
  enable_vpc_flow_logs   = true

  # Features - all enabled for production
  enable_codepipeline = false # Using GitHub Actions instead
  enable_xray_tracing = true  # Full tracing for production debugging

  # Backup configuration - comprehensive backup strategy
  backup_config = {
    enable_backups        = true
    backup_retention_days = 90                  # Extended retention for production
    backup_schedule       = "cron(0 2 * * ? *)" # Daily backups at 2 AM
  }

  # Production optimization - performance over cost
  cost_optimization = {
    use_spot_instances                      = false # Reliability over cost for production
    enable_auto_scaling                     = true
    schedule_lambda_provisioned_concurrency = true # Performance for real-time chat
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "infrastructure_summary" {
  description = "Summary of production infrastructure"
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
  }
  sensitive = false
}

output "api_endpoints" {
  description = "API endpoints for iOS app integration"
  value = {
    rest_api_url     = module.infrastructure.api_endpoints.rest_api_base_url
    websocket_url    = module.infrastructure.api_endpoints.websocket_url
    health_check_url = module.infrastructure.api_endpoints.health_check_url
  }
  sensitive = false
}

output "secrets_info" {
  description = "Secrets Manager ARNs for Lambda access"
  value = {
    openai_api_key_arn   = module.infrastructure.secrets.openai_api_key_arn
    apple_signin_key_arn = module.infrastructure.secrets.apple_signin_key_arn
    jwt_secret_arn       = module.infrastructure.secrets.jwt_secret_arn
  }
  sensitive = false
}