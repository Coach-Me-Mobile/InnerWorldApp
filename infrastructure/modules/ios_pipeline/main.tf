# ==============================================================================
# IOS PIPELINE MODULE FOR TESTFLIGHT DEPLOYMENT
# ==============================================================================
# AWS CodePipeline and CodeBuild for iOS CI/CD automation
# Handles iOS build, testing, and TestFlight deployment for InnerWorldApp
# ==============================================================================

# ==============================================================================
# S3 BUCKET FOR ARTIFACTS
# ==============================================================================

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.name_prefix}-ios-pipeline-artifacts"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-ios-pipeline-artifacts"
    Type    = "S3Bucket"
    Purpose = "iOSPipelineArtifacts"
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
  name = "${var.name_prefix}-ios-pipeline-role"

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
    Name = "${var.name_prefix}-ios-pipeline-role"
    Type = "IAMRole"
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.name_prefix}-ios-pipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*",
          var.testflight_builds_bucket_arn,
          "${var.testflight_builds_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [
          aws_codebuild_project.ios_build.arn,
          aws_codebuild_project.ios_test.arn,
          aws_codebuild_project.testflight_deploy.arn
        ]
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
  name = "${var.name_prefix}-ios-codebuild-role"

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
    Name = "${var.name_prefix}-ios-codebuild-role"
    Type = "IAMRole"
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.name_prefix}-ios-codebuild-policy"
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
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*",
          var.testflight_builds_bucket_arn,
          "${var.testflight_builds_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.apple_developer_secrets_arn,
          var.app_store_connect_secrets_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.name_prefix}/*"
      }
    ]
  })
}

# ==============================================================================
# CODEBUILD PROJECT FOR IOS BUILD
# ==============================================================================

resource "aws_codebuild_project" "ios_build" {
  name         = "${var.name_prefix}-ios-build"
  description  = "Build iOS app for InnerWorld"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_LARGE"       # Increased for iOS builds
    image                       = "aws/codebuild/standard:7.0" # macOS support
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

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
      name  = "TESTFLIGHT_BUILDS_BUCKET"
      value = var.testflight_builds_bucket_name
    }

    environment_variable {
      name  = "APPLE_DEVELOPER_SECRETS_ARN"
      value = var.apple_developer_secrets_arn
    }

    environment_variable {
      name  = "APP_STORE_CONNECT_SECRETS_ARN"
      value = var.app_store_connect_secrets_arn
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/ios-build.yml"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}/cache/ios-build"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-build"
    Type = "CodeBuildProject"
  })
}

# ==============================================================================
# CODEBUILD PROJECT FOR IOS TESTING
# ==============================================================================

resource "aws_codebuild_project" "ios_test" {
  name         = "${var.name_prefix}-ios-test"
  description  = "Test iOS app for InnerWorld"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

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
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/ios-test.yml"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}/cache/ios-test"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-test"
    Type = "CodeBuildProject"
  })
}

# ==============================================================================
# CODEBUILD PROJECT FOR TESTFLIGHT DEPLOYMENT
# ==============================================================================

resource "aws_codebuild_project" "testflight_deploy" {
  name         = "${var.name_prefix}-testflight-deploy"
  description  = "Deploy iOS app to TestFlight"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

    environment_variable {
      name  = "TESTFLIGHT_BUILDS_BUCKET"
      value = var.testflight_builds_bucket_name
    }

    environment_variable {
      name  = "APP_STORE_CONNECT_SECRETS_ARN"
      value = var.app_store_connect_secrets_arn
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/testflight-deploy.yml"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-testflight-deploy"
    Type = "CodeBuildProject"
  })
}

# ==============================================================================
# CODEPIPELINE FOR IOS CI/CD
# ==============================================================================

resource "aws_codepipeline" "ios_pipeline" {
  name     = "${var.name_prefix}-ios-pipeline"
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
        DetectChanges    = true
      }
    }
  }

  # iOS Build stage
  stage {
    name = "Build"

    action {
      name             = "BuildiOS"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ios_build.name
      }
    }
  }

  # iOS Test stage
  stage {
    name = "Test"

    action {
      name             = "TestiOS"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["build_output"]
      output_artifacts = ["test_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ios_test.name
      }
    }
  }

  # Manual approval for TestFlight deployment
  dynamic "stage" {
    for_each = var.require_manual_approval ? [1] : []
    content {
      name = "ManualApproval"

      action {
        name     = "ApprovalForTestFlight"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          CustomData = "Please review the build and approve deployment to TestFlight."
        }
      }
    }
  }

  # TestFlight deployment stage
  stage {
    name = "DeployToTestFlight"

    action {
      name             = "DeployTestFlight"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["test_output"]
      output_artifacts = ["deploy_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.testflight_deploy.name
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-pipeline"
    Type = "CodePipeline"
  })
}

# ==============================================================================
# CLOUDWATCH LOG GROUPS
# ==============================================================================

resource "aws_cloudwatch_log_group" "ios_build" {
  name              = "/aws/codebuild/${aws_codebuild_project.ios_build.name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-build-logs"
    Type = "CloudWatchLogGroup"
  })
}

resource "aws_cloudwatch_log_group" "ios_test" {
  name              = "/aws/codebuild/${aws_codebuild_project.ios_test.name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-test-logs"
    Type = "CloudWatchLogGroup"
  })
}

resource "aws_cloudwatch_log_group" "testflight_deploy" {
  name              = "/aws/codebuild/${aws_codebuild_project.testflight_deploy.name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-testflight-deploy-logs"
    Type = "CloudWatchLogGroup"
  })
}

# ==============================================================================
# CLOUDWATCH ALARMS FOR PIPELINE MONITORING
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "pipeline_failed" {
  alarm_name          = "${var.name_prefix}-ios-pipeline-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "PipelineExecutionFailure"
  namespace           = "AWS/CodePipeline"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors iOS pipeline failures"

  dimensions = {
    PipelineName = aws_codepipeline.ios_pipeline.name
  }

  alarm_actions = var.alarm_actions

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-pipeline-failed-alarm"
    Type = "CloudWatchAlarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "build_failed" {
  alarm_name          = "${var.name_prefix}-ios-build-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedBuilds"
  namespace           = "AWS/CodeBuild"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors iOS build failures"

  dimensions = {
    ProjectName = aws_codebuild_project.ios_build.name
  }

  alarm_actions = var.alarm_actions

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ios-build-failed-alarm"
    Type = "CloudWatchAlarm"
  })
}
