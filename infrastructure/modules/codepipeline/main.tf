# ==============================================================================
# CODEPIPELINE MODULE
# ==============================================================================
# AWS CodePipeline and CodeBuild for CI/CD automation
# Handles build, test, and deployment for InnerWorldApp
# ==============================================================================

# ==============================================================================
# S3 BUCKET FOR ARTIFACTS
# ==============================================================================

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.name_prefix}-codepipeline-artifacts"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-codepipeline-artifacts"
    Type = "S3Bucket"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  rule {
    id     = "delete_old_artifacts"
    status = "Enabled"
    
    filter {
      prefix = ""
    }
    
    expiration {
      days = 30
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# ==============================================================================
# IAM ROLE FOR CODEPIPELINE
# ==============================================================================

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name_prefix}-codepipeline-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-codepipeline-role"
    Type = "IAMRole"
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = var.github_connection_arn
      }
    ]
  })
}

# ==============================================================================
# IAM ROLE FOR CODEBUILD
# ==============================================================================

resource "aws_iam_role" "codebuild_role" {
  name = "${var.name_prefix}-codebuild-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-codebuild-role"
    Type = "IAMRole"
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.name_prefix}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.name_prefix}*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.name_prefix}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/${var.name_prefix}/*"
        ]
      }
    ]
  })
}

# ==============================================================================
# CODEBUILD PROJECT FOR iOS
# ==============================================================================

resource "aws_codebuild_project" "ios_build" {
  name          = "${var.name_prefix}-ios-build"
  description   = "Build and test iOS app for InnerWorld"
  service_role  = aws_iam_role.codebuild_role.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = false
    
    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }
    
    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
    
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
  }
  
  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-ios.yml"
  }
  
  cache {
    type  = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}/cache"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-build"
    Type = "CodeBuildProject"
  })
}

# ==============================================================================
# CODEBUILD PROJECT FOR INFRASTRUCTURE
# ==============================================================================

resource "aws_codebuild_project" "infrastructure_build" {
  name          = "${var.name_prefix}-infrastructure-build"
  description   = "Validate and deploy Terraform infrastructure"
  service_role  = aws_iam_role.codebuild_role.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = false
    
    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }
    
    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
    
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    
    environment_variable {
      name  = "TF_IN_AUTOMATION"
      value = "true"
    }
  }
  
  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-infrastructure.yml"
  }
  
  cache {
    type  = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}/terraform-cache"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-infrastructure-build"
    Type = "CodeBuildProject"
  })
}

# ==============================================================================
# CODEBUILD PROJECT FOR SECURITY SCANS
# ==============================================================================

resource "aws_codebuild_project" "security_scan" {
  name          = "${var.name_prefix}-security-scan"
  description   = "Security scanning for code and dependencies"
  service_role  = aws_iam_role.codebuild_role.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = false
    
    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }
    
    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }
  
  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-security.yml"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-security-scan"
    Type = "CodeBuildProject"
  })
}

# ==============================================================================
# CODEPIPELINE
# ==============================================================================

resource "aws_codepipeline" "main" {
  name     = "${var.name_prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  
  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }
  
  # Source stage
  stage {
    name = "Source"
    
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      
      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
      }
    }
  }
  
  # Security scan stage
  stage {
    name = "SecurityScan"
    
    action {
      name             = "SecurityScan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["security_output"]
      version          = "1"
      
      configuration = {
        ProjectName = aws_codebuild_project.security_scan.name
      }
    }
  }
  
  # Infrastructure validation stage
  stage {
    name = "InfrastructureValidation"
    
    action {
      name             = "ValidateInfrastructure"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["infrastructure_output"]
      version          = "1"
      
      configuration = {
        ProjectName = aws_codebuild_project.infrastructure_build.name
      }
    }
  }
  
  # iOS build and test stage
  stage {
    name = "iOSBuildAndTest"
    
    action {
      name             = "BuildiOS"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["ios_output"]
      version          = "1"
      
      configuration = {
        ProjectName = aws_codebuild_project.ios_build.name
      }
    }
  }
  
  # Manual approval for production deployments
  dynamic "stage" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      name = "ManualApproval"
      
      action {
        name     = "ManualApproval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"
        
        configuration = {
          CustomData = "Please review the build artifacts and approve deployment to production."
        }
      }
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-pipeline"
    Type = "CodePipeline"
  })
}

# ==============================================================================
# CLOUDWATCH LOG GROUPS
# ==============================================================================

resource "aws_cloudwatch_log_group" "codebuild_ios" {
  name              = "/aws/codebuild/${aws_codebuild_project.ios_build.name}"
  retention_in_days = var.log_retention_days
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-codebuild-ios-logs"
    Type = "CloudWatchLogGroup"
  })
}

resource "aws_cloudwatch_log_group" "codebuild_infrastructure" {
  name              = "/aws/codebuild/${aws_codebuild_project.infrastructure_build.name}"
  retention_in_days = var.log_retention_days
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-codebuild-infrastructure-logs"
    Type = "CloudWatchLogGroup"
  })
}

resource "aws_cloudwatch_log_group" "codebuild_security" {
  name              = "/aws/codebuild/${aws_codebuild_project.security_scan.name}"
  retention_in_days = var.log_retention_days
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-codebuild-security-logs"
    Type = "CloudWatchLogGroup"
  })
}

# ==============================================================================
# CLOUDWATCH ALARMS FOR PIPELINE MONITORING
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "pipeline_failed" {
  alarm_name          = "${var.name_prefix}-pipeline-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "PipelineExecutionFailure"
  namespace           = "AWS/CodePipeline"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors pipeline failures"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  
  dimensions = {
    PipelineName = aws_codepipeline.main.name
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-pipeline-failed-alarm"
    Type = "CloudWatchAlarm"
  })
}

# ==============================================================================
# SSM PARAMETERS FOR BUILD CONFIGURATION
# ==============================================================================

resource "aws_ssm_parameter" "build_config" {
  name  = "/${var.name_prefix}/build/config"
  type  = "String"
  value = jsonencode({
    project_name = var.project_name
    environment  = var.environment
    aws_region   = var.aws_region
    build_version = "1.0.0"
    
    ios_config = {
      xcode_version = "15.1"
      ios_version   = "17.0"
      scheme        = "InnerWorldApp"
      configuration = var.environment == "prod" ? "Release" : "Debug"
    }
    
    security_config = {
      enable_sast_scan = true
      enable_dependency_scan = true
      enable_secret_scan = true
      fail_on_high_severity = var.environment == "prod"
    }
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-build-config"
    Type = "SSMParameter"
  })
}
