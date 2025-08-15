# ==============================================================================
# OUTPUTS CONFIGURATION
# ==============================================================================
# Output values for InnerWorldApp infrastructure
# These outputs are used by other configurations and for information display
# ==============================================================================

# ==============================================================================
# PROJECT INFORMATION
# ==============================================================================

output "project_info" {
  description = "Project information and metadata"
  value = {
    project_name = var.project_name
    environment  = var.environment
    aws_region   = var.aws_region
    account_id   = local.account_id
    name_prefix  = local.name_prefix
  }
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "vpc" {
  description = "VPC configuration and details"
  value = {
    vpc_id              = module.networking.vpc_id
    vpc_cidr_block      = module.networking.vpc_cidr_block
    availability_zones  = module.networking.availability_zones
    public_subnet_ids   = module.networking.public_subnet_ids
    private_subnet_ids  = module.networking.private_subnet_ids
    nat_gateway_ids     = module.networking.nat_gateway_ids
    internet_gateway_id = module.networking.internet_gateway_id
  }
  sensitive = false
}

output "security_groups" {
  description = "Security group IDs for different services"
  value = {
    default_sg_id = module.networking.default_security_group_id
    lambda_sg_id  = module.networking.lambda_security_group_id
    neptune_sg_id = module.networking.neptune_security_group_id
  }
  sensitive = false
}

# ==============================================================================
# COGNITO OUTPUTS
# ==============================================================================

output "cognito" {
  description = "Cognito User Pool and Identity Pool information"
  value = {
    user_pool_id        = module.cognito.user_pool_id
    user_pool_arn       = module.cognito.user_pool_arn
    user_pool_domain    = module.cognito.user_pool_domain
    user_pool_client_id = module.cognito.user_pool_client_id
    identity_pool_id    = module.cognito.identity_pool_id
    identity_pool_arn   = module.cognito.identity_pool_arn
  }
  sensitive = false
}

output "cognito_urls" {
  description = "Cognito service URLs and endpoints"
  value = {
    user_pool_endpoint = module.cognito.user_pool_endpoint
    login_url          = module.cognito.login_url
    logout_url         = module.cognito.logout_url
    jwks_uri           = module.cognito.jwks_uri
  }
  sensitive = false
}

# ==============================================================================
# S3 OUTPUTS
# ==============================================================================

output "s3" {
  description = "S3 buckets and CloudFront distribution information"
  value = {
    app_assets_bucket_name        = module.s3.app_assets_bucket_name
    app_assets_bucket_arn         = module.s3.app_assets_bucket_arn
    testflight_builds_bucket_name = module.s3.testflight_builds_bucket_name
    testflight_builds_bucket_arn  = module.s3.testflight_builds_bucket_arn
    cloudfront_distribution_id    = module.s3.cloudfront_distribution_id
    cloudfront_domain_name        = module.s3.cloudfront_domain_name
    s3_access_policy_arn          = module.s3.s3_access_policy_arn
  }
  sensitive = false
}

# ==============================================================================
# SECRETS MANAGER OUTPUTS
# ==============================================================================

output "secrets" {
  description = "AWS Secrets Manager secret ARNs and names"
  value = {
    openrouter_api_key_arn    = module.secrets.openrouter_api_key_arn
    neptune_config_arn        = module.secrets.neptune_config_arn
    apple_signin_key_arn      = module.secrets.apple_signin_key_arn
    app_store_connect_key_arn = module.secrets.app_store_connect_key_arn
    jwt_secret_arn            = module.secrets.jwt_secret_arn
  }
  sensitive = false
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "iam_roles" {
  description = "IAM role ARNs for different services"
  value = {
    lambda_execution_role_arn        = module.cognito.lambda_execution_role_arn
    cognito_authenticated_role_arn   = module.cognito.cognito_authenticated_role_arn
    cognito_unauthenticated_role_arn = module.cognito.cognito_unauthenticated_role_arn
  }
  sensitive = false
}

# ==============================================================================
# CODEPIPELINE OUTPUTS
# ==============================================================================

# ==============================================================================
# GITHUB ACTIONS INTEGRATION
# ==============================================================================

output "github_actions_resources" {
  description = "AWS resources available for GitHub Actions CI/CD"
  value = {
    # S3 buckets for artifacts and builds
    app_assets_bucket        = module.s3.app_assets_bucket_name
    testflight_builds_bucket = module.s3.testflight_builds_bucket_name

    # Secrets for GitHub Actions
    apple_signin_secret_arn      = module.secrets.apple_signin_key_arn
    app_store_connect_secret_arn = module.secrets.app_store_connect_key_arn
    openrouter_api_secret_arn    = module.secrets.openrouter_api_key_arn

    # AWS region for GitHub Actions
    aws_region = var.aws_region

    # GitHub Actions IAM user
    github_actions_user = module.s3.github_actions_user_name
  }
  sensitive = false
}

output "github_actions_credentials" {
  description = "AWS credentials for GitHub Actions (sensitive)"
  value = {
    access_key_id     = module.s3.github_actions_access_key_id
    secret_access_key = module.s3.github_actions_secret_access_key
    region            = var.aws_region
  }
  sensitive = true
}

# ==============================================================================
# BACKEND STATE OUTPUTS
# ==============================================================================

output "backend_config" {
  description = "Terraform backend configuration for remote state"
  value = {
    s3_bucket_name      = "innerworld-${var.environment}-terraform-state"
    s3_bucket_region    = var.aws_region
    dynamodb_table_name = "innerworld-${var.environment}-terraform-locks"
    state_key_prefix    = "terraform.tfstate"
  }
  sensitive = false
}

# ==============================================================================
# MONITORING OUTPUTS
# ==============================================================================

output "monitoring" {
  description = "Monitoring and logging configuration"
  value = {
    cloudwatch_log_groups = var.enable_cloudwatch_logs ? {
      lambda_log_group   = "/aws/lambda/${local.name_prefix}"
      vpc_flow_log_group = "/aws/vpc/flowlogs/${local.name_prefix}"
    } : null

    log_retention_days = var.log_retention_days
  }
  sensitive = false
}

# ==============================================================================
# COST TRACKING OUTPUTS
# ==============================================================================

output "cost_tracking" {
  description = "Cost tracking and resource tagging information"
  value = {
    common_tags = local.common_tags
    name_prefix = local.name_prefix
    environment = var.environment
  }
  sensitive = false
}

# ==============================================================================
# LAMBDA OUTPUTS
# ==============================================================================

output "lambda" {
  description = "Lambda functions information"
  value = {
    functions          = module.lambda.lambda_functions_summary
    api_gateways       = module.lambda.api_gateways_summary
    execution_role_arn = module.lambda.lambda_execution_role_arn
  }
  sensitive = false
}

output "api_endpoints" {
  description = "API endpoint URLs for testing and integration"
  value = {
    rest_api_base_url = module.lambda.rest_api_endpoint
    health_check_url  = module.lambda.rest_api_health_endpoint
    websocket_url     = module.lambda.websocket_api_endpoint
  }
  sensitive = false
}

# ==============================================================================
# CONFIGURATION SUMMARY
# ==============================================================================

output "infrastructure_summary" {
  description = "Summary of infrastructure configuration and status"
  value = {
    # Core infrastructure
    vpc_created           = true
    cognito_configured    = true
    secrets_manager_setup = true
    lambda_deployed       = true

    # Optional features
    codepipeline_enabled  = false
    cloudwatch_enabled    = var.enable_cloudwatch_logs
    vpc_flow_logs_enabled = var.enable_vpc_flow_logs

    # Environment configuration
    is_production     = var.environment == "prod"
    nat_gateway_count = var.single_nat_gateway ? 1 : length(local.azs)

    # Security features
    mfa_configuration = var.cognito_config.mfa_configuration
    backup_enabled    = var.backup_config.enable_backups

    # API endpoints
    rest_api_url  = module.lambda.rest_api_endpoint
    websocket_url = module.lambda.websocket_api_endpoint
  }
  sensitive = false
}
