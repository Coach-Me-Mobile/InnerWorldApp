# ==============================================================================
# OUTPUTS FOR S3 MODULE
# ==============================================================================

# ==============================================================================
# S3 BUCKET OUTPUTS
# ==============================================================================

output "app_assets_bucket_name" {
  description = "Name of the app assets S3 bucket"
  value       = aws_s3_bucket.app_assets.bucket
}

output "app_assets_bucket_arn" {
  description = "ARN of the app assets S3 bucket"
  value       = aws_s3_bucket.app_assets.arn
}

output "app_assets_bucket_id" {
  description = "ID of the app assets S3 bucket"
  value       = aws_s3_bucket.app_assets.id
}

output "app_assets_bucket_regional_domain_name" {
  description = "Regional domain name of the app assets S3 bucket"
  value       = aws_s3_bucket.app_assets.bucket_regional_domain_name
}

output "testflight_builds_bucket_name" {
  description = "Name of the TestFlight builds S3 bucket"
  value       = aws_s3_bucket.testflight_builds.bucket
}

output "testflight_builds_bucket_arn" {
  description = "ARN of the TestFlight builds S3 bucket"
  value       = aws_s3_bucket.testflight_builds.arn
}

output "testflight_builds_bucket_id" {
  description = "ID of the TestFlight builds S3 bucket"
  value       = aws_s3_bucket.testflight_builds.id
}

# ==============================================================================
# CLOUDFRONT OUTPUTS
# ==============================================================================

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.app_assets[0].id : null
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.app_assets[0].arn : null
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.app_assets[0].domain_name : null
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.app_assets[0].hosted_zone_id : null
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "s3_access_policy_arn" {
  description = "ARN of the S3 access policy"
  value       = aws_iam_policy.s3_access.arn
}

output "s3_access_policy_name" {
  description = "Name of the S3 access policy"
  value       = aws_iam_policy.s3_access.name
}

# ==============================================================================
# SUMMARY OUTPUTS
# ==============================================================================

output "s3_summary" {
  description = "Summary of S3 configuration"
  value = {
    app_assets_bucket     = aws_s3_bucket.app_assets.bucket
    testflight_builds_bucket = aws_s3_bucket.testflight_builds.bucket
    cloudfront_enabled    = var.enable_cloudfront
    cloudfront_domain     = var.enable_cloudfront ? aws_cloudfront_distribution.app_assets[0].domain_name : null
  }
}
