# ==============================================================================
# TERRAFORM BACKEND INFRASTRUCTURE
# ==============================================================================
# Creates S3 bucket and DynamoDB table for Terraform remote state
# This should be run first before any other infrastructure
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # No backend configuration here - this creates the backend infrastructure
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "innerworld"
      Purpose     = "TerraformBackend"
      ManagedBy   = "Terraform"
      Repository  = "InnerWorldApp"
      Team        = "GauntletAI"
    }
  }
}

# ==============================================================================
# VARIABLES
# ==============================================================================

variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "us-east-1"
}

variable "environments" {
  description = "List of environments to create backend for"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

# ==============================================================================
# S3 BUCKETS FOR TERRAFORM STATE
# ==============================================================================

resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(var.environments)
  
  bucket = "innerworld-${each.value}-terraform-state"
  
  tags = {
    Name        = "innerworld-${each.value}-terraform-state"
    Environment = each.value
    Type        = "TerraformStateBucket"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state
  
  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state
  
  bucket = each.value.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state
  
  bucket = each.value.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state
  
  bucket = each.value.id
  
  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = ""
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

# ==============================================================================
# DYNAMODB TABLES FOR TERRAFORM LOCKS
# ==============================================================================

resource "aws_dynamodb_table" "terraform_locks" {
  for_each = toset(var.environments)
  
  name           = "innerworld-${each.value}-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = "innerworld-${each.value}-terraform-locks"
    Environment = each.value
    Type        = "TerraformLockTable"
  }
}

# ==============================================================================
# IAM POLICY FOR TERRAFORM BACKEND ACCESS
# ==============================================================================

data "aws_iam_policy_document" "terraform_backend" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning"
    ]
    
    resources = [for bucket in aws_s3_bucket.terraform_state : bucket.arn]
  }
  
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    
    resources = [for bucket in aws_s3_bucket.terraform_state : "${bucket.arn}/*"]
  }
  
  statement {
    effect = "Allow"
    
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    
    resources = [for table in aws_dynamodb_table.terraform_locks : table.arn]
  }
}

resource "aws_iam_policy" "terraform_backend" {
  name_prefix = "innerworld-terraform-backend-"
  description = "IAM policy for Terraform backend access"
  policy      = data.aws_iam_policy_document.terraform_backend.json
  
  tags = {
    Name = "innerworld-terraform-backend-policy"
    Type = "IAMPolicy"
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "s3_bucket_names" {
  description = "Names of S3 buckets for Terraform state"
  value = {
    for env, bucket in aws_s3_bucket.terraform_state : env => bucket.bucket
  }
}

output "dynamodb_table_names" {
  description = "Names of DynamoDB tables for Terraform locks"
  value = {
    for env, table in aws_dynamodb_table.terraform_locks : env => table.name
  }
}

output "backend_config" {
  description = "Backend configuration for each environment"
  value = {
    for env in var.environments : env => {
      bucket         = aws_s3_bucket.terraform_state[env].bucket
      key            = "${env}/terraform.tfstate"
      region         = var.aws_region
      dynamodb_table = aws_dynamodb_table.terraform_locks[env].name
      encrypt        = true
    }
  }
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy for Terraform backend access"
  value       = aws_iam_policy.terraform_backend.arn
}
