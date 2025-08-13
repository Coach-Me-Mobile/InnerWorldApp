# ==============================================================================
# CODEPIPELINE MODULE OUTPUTS
# ==============================================================================
# Output values from the CodePipeline module
# ==============================================================================

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.main.name
  sensitive   = false
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.main.arn
  sensitive   = false
}

output "s3_artifacts_bucket" {
  description = "Name of the S3 artifacts bucket"
  value       = aws_s3_bucket.artifacts.bucket
  sensitive   = false
}

output "s3_artifacts_bucket_arn" {
  description = "ARN of the S3 artifacts bucket"
  value       = aws_s3_bucket.artifacts.arn
  sensitive   = false
}

# ==============================================================================
# CODEBUILD PROJECT OUTPUTS
# ==============================================================================

output "codebuild_project_name" {
  description = "Name of the primary CodeBuild project"
  value       = aws_codebuild_project.ios_build.name
  sensitive   = false
}

output "codebuild_ios_project_arn" {
  description = "ARN of the iOS CodeBuild project"
  value       = aws_codebuild_project.ios_build.arn
  sensitive   = false
}

output "codebuild_infrastructure_project_arn" {
  description = "ARN of the infrastructure CodeBuild project"
  value       = aws_codebuild_project.infrastructure_build.arn
  sensitive   = false
}

output "codebuild_security_project_arn" {
  description = "ARN of the security scan CodeBuild project"
  value       = aws_codebuild_project.security_scan.arn
  sensitive   = false
}

# ==============================================================================
# IAM ROLE OUTPUTS
# ==============================================================================

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = aws_iam_role.codepipeline_role.arn
  sensitive   = false
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = aws_iam_role.codebuild_role.arn
  sensitive   = false
}

# ==============================================================================
# CLOUDWATCH OUTPUTS
# ==============================================================================

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names for CodeBuild projects"
  value = {
    ios_build      = aws_cloudwatch_log_group.codebuild_ios.name
    infrastructure = aws_cloudwatch_log_group.codebuild_infrastructure.name
    security_scan  = aws_cloudwatch_log_group.codebuild_security.name
  }
  sensitive = false
}

output "pipeline_alarm_arn" {
  description = "ARN of the pipeline failure CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.pipeline_failed.arn
  sensitive   = false
}

# ==============================================================================
# CONFIGURATION OUTPUTS
# ==============================================================================

output "build_config_parameter_name" {
  description = "Name of the SSM parameter containing build configuration"
  value       = aws_ssm_parameter.build_config.name
  sensitive   = false
}

output "pipeline_config" {
  description = "Pipeline configuration summary"
  value = {
    pipeline_name     = aws_codepipeline.main.name
    artifacts_bucket  = aws_s3_bucket.artifacts.bucket
    github_repository = var.github_repository
    github_branch     = var.github_branch
    environment       = var.environment
    
    stages = [
      "Source",
      "SecurityScan",
      "InfrastructureValidation",
      "iOSBuildAndTest"
    ]
    
    codebuild_projects = {
      ios_build      = aws_codebuild_project.ios_build.name
      infrastructure = aws_codebuild_project.infrastructure_build.name
      security_scan  = aws_codebuild_project.security_scan.name
    }
  }
  sensitive = false
}
