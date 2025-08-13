# ==============================================================================
# TERRAFORM CONFIGURATION
# ==============================================================================
# Main Terraform configuration for InnerWorldApp infrastructure
# This file defines the core terraform settings, providers, and backend config
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Remote state backend configuration
  # This will be uncommented after the S3 bucket and DynamoDB table are created
  # backend "s3" {
  #   bucket         = "innerworld-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = var.aws_region
  #   dynamodb_table = "innerworld-terraform-locks"
  #   encrypt        = true
  # }
}

# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "InnerWorldApp"
      Team        = "GauntletAI"
    }
  }
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get available AZs for the region
data "aws_availability_zones" "available" {
  state = "available"
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  # Common naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Account and region info
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  # AZ configuration - use first 3 AZs for redundancy
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)
  
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "InnerWorldApp"
    Team        = "GauntletAI"
    AccountId   = local.account_id
    Region      = local.region
  }
}

# ==============================================================================
# MODULE INSTANTIATIONS
# ==============================================================================

# Networking module - VPC, subnets, security groups
module "networking" {
  source = "./modules/networking"
  
  name_prefix           = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.azs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_vpc_flow_logs = var.enable_vpc_flow_logs
  aws_region          = var.aws_region
  
  tags = local.common_tags
}

# Secrets module - API keys and credentials
module "secrets" {
  source = "./modules/secrets"
  
  name_prefix            = local.name_prefix
  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  recovery_window_days  = var.secrets_config.recovery_window_days
  enable_secret_rotation = false # Enable later if needed
  
  tags = local.common_tags
}

# Cognito module - Authentication and authorization
module "cognito" {
  source = "./modules/cognito"
  
  name_prefix    = local.name_prefix
  project_name   = var.project_name
  environment    = var.environment
  aws_region     = var.aws_region
  account_id     = local.account_id
  
  # Cognito configuration
  enable_apple_signin           = var.cognito_config.enable_apple_signin
  enable_email_signin          = var.cognito_config.enable_email_signin
  email_verification_required  = var.cognito_config.email_verification_required
  phone_verification_required  = var.cognito_config.phone_verification_required
  password_policy_min_length   = var.cognito_config.password_policy_min_length
  password_policy_require_uppercase = var.cognito_config.password_policy_require_uppercase
  password_policy_require_lowercase = var.cognito_config.password_policy_require_lowercase
  password_policy_require_numbers   = var.cognito_config.password_policy_require_numbers
  password_policy_require_symbols   = var.cognito_config.password_policy_require_symbols
  mfa_configuration            = var.cognito_config.mfa_configuration
  
  # Lambda triggers (disabled by default)
  enable_lambda_triggers = false
  
  tags = local.common_tags
}

# CodePipeline module - CI/CD pipeline
module "codepipeline" {
  count  = var.enable_codepipeline ? 1 : 0
  source = "./modules/codepipeline"
  
  name_prefix             = local.name_prefix
  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  
  # GitHub configuration - these will need to be set via terraform.tfvars
  github_connection_arn  = var.github_connection_arn
  github_repository      = var.github_repository
  github_branch          = var.github_branch
  
  log_retention_days     = var.log_retention_days
  
  tags = local.common_tags
}
