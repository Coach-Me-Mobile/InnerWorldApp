# ==============================================================================
# OUTPUTS FOR IOS PIPELINE MODULE
# ==============================================================================

# ==============================================================================
# PIPELINE OUTPUTS
# ==============================================================================

output "pipeline_name" {
  description = "Name of the iOS CI/CD pipeline"
  value       = aws_codepipeline.ios_pipeline.name
}

output "pipeline_arn" {
  description = "ARN of the iOS CI/CD pipeline"
  value       = aws_codepipeline.ios_pipeline.arn
}

output "pipeline_id" {
  description = "ID of the iOS CI/CD pipeline"
  value       = aws_codepipeline.ios_pipeline.id
}

# ==============================================================================
# CODEBUILD PROJECT OUTPUTS
# ==============================================================================

output "ios_build_project_name" {
  description = "Name of the iOS build CodeBuild project"
  value       = aws_codebuild_project.ios_build.name
}

output "ios_build_project_arn" {
  description = "ARN of the iOS build CodeBuild project"
  value       = aws_codebuild_project.ios_build.arn
}

output "ios_test_project_name" {
  description = "Name of the iOS test CodeBuild project"
  value       = aws_codebuild_project.ios_test.name
}

output "ios_test_project_arn" {
  description = "ARN of the iOS test CodeBuild project"
  value       = aws_codebuild_project.ios_test.arn
}

output "testflight_deploy_project_name" {
  description = "Name of the TestFlight deployment CodeBuild project"
  value       = aws_codebuild_project.testflight_deploy.name
}

output "testflight_deploy_project_arn" {
  description = "ARN of the TestFlight deployment CodeBuild project"
  value       = aws_codebuild_project.testflight_deploy.arn
}

# ==============================================================================
# S3 OUTPUTS
# ==============================================================================

output "artifacts_bucket_name" {
  description = "Name of the pipeline artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the pipeline artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline IAM role"
  value       = aws_iam_role.codepipeline_role.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild IAM role"
  value       = aws_iam_role.codebuild_role.arn
}

# ==============================================================================
# CLOUDWATCH OUTPUTS
# ==============================================================================

output "log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    ios_build          = aws_cloudwatch_log_group.ios_build.name
    ios_test           = aws_cloudwatch_log_group.ios_test.name
    testflight_deploy  = aws_cloudwatch_log_group.testflight_deploy.name
  }
}

output "alarm_names" {
  description = "Map of CloudWatch alarm names"
  value = {
    pipeline_failed = aws_cloudwatch_metric_alarm.pipeline_failed.alarm_name
    build_failed    = aws_cloudwatch_metric_alarm.build_failed.alarm_name
  }
}

# ==============================================================================
# SUMMARY OUTPUT
# ==============================================================================

output "ios_pipeline_summary" {
  description = "Summary of iOS pipeline configuration"
  value = {
    pipeline_name              = aws_codepipeline.ios_pipeline.name
    pipeline_arn               = aws_codepipeline.ios_pipeline.arn
    artifacts_bucket           = aws_s3_bucket.artifacts.bucket
    github_repository          = var.github_repository
    github_branch              = var.github_branch
    requires_manual_approval   = var.require_manual_approval
    build_projects = {
      ios_build         = aws_codebuild_project.ios_build.name
      ios_test          = aws_codebuild_project.ios_test.name
      testflight_deploy = aws_codebuild_project.testflight_deploy.name
    }
  }
}
