# ==============================================================================
# S3 BUCKET MODULE FOR APP ASSETS STORAGE
# ==============================================================================
# S3 buckets for storing app assets, build artifacts, and static content
# Includes CloudFront distribution for global content delivery
# ==============================================================================

# ==============================================================================
# S3 BUCKET FOR APP ASSETS
# ==============================================================================

resource "aws_s3_bucket" "app_assets" {
  bucket = "${var.name_prefix}-app-assets"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-app-assets"
    Type    = "S3Bucket"
    Purpose = "AppAssets"
  })
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (assets will be served via CloudFront)
resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  rule {
    id     = "app_assets_lifecycle"
    status = "Enabled"

    # Delete old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Archive to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# ==============================================================================
# S3 BUCKET FOR TESTFLIGHT BUILDS
# ==============================================================================

resource "aws_s3_bucket" "testflight_builds" {
  bucket = "${var.name_prefix}-testflight-builds"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-testflight-builds"
    Type    = "S3Bucket"
    Purpose = "TestFlightBuilds"
  })
}

# Bucket versioning for builds
resource "aws_s3_bucket_versioning" "testflight_builds" {
  bucket = aws_s3_bucket.testflight_builds.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket encryption for builds
resource "aws_s3_bucket_server_side_encryption_configuration" "testflight_builds" {
  bucket = aws_s3_bucket.testflight_builds.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for builds
resource "aws_s3_bucket_public_access_block" "testflight_builds" {
  bucket = aws_s3_bucket.testflight_builds.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration for builds (shorter retention)
resource "aws_s3_bucket_lifecycle_configuration" "testflight_builds" {
  bucket = aws_s3_bucket.testflight_builds.id

  rule {
    id     = "testflight_builds_lifecycle"
    status = "Enabled"

    # Delete current versions after 90 days
    expiration {
      days = 90
    }

    # Delete old versions after 7 days
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# ==============================================================================
# CLOUDFRONT DISTRIBUTION FOR APP ASSETS
# ==============================================================================

# Origin Access Control for CloudFront
resource "aws_cloudfront_origin_access_control" "app_assets" {
  name                              = "${var.name_prefix}-app-assets-oac"
  description                       = "Origin Access Control for app assets S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "app_assets" {
  count = var.enable_cloudfront ? 1 : 0

  origin {
    domain_name              = aws_s3_bucket.app_assets.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.app_assets.id
    origin_id                = "S3-${aws_s3_bucket.app_assets.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix} app assets distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.app_assets.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior for static assets (images, videos, etc.)
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.app_assets.id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400    # 1 day
    max_ttl                = 31536000 # 1 year
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-assets-cloudfront"
    Type = "CloudFrontDistribution"
  })

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "app_assets_cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.app_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.app_assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.app_assets[0].arn
          }
        }
      }
    ]
  })
}

# ==============================================================================
# IAM POLICIES FOR GITHUB ACTIONS S3 ACCESS
# ==============================================================================

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.app_assets.arn,
      "${aws_s3_bucket.app_assets.arn}/*",
      aws_s3_bucket.testflight_builds.arn,
      "${aws_s3_bucket.testflight_builds.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = var.enable_cloudfront ? [aws_cloudfront_distribution.app_assets[0].arn] : []
  }
}

resource "aws_iam_policy" "s3_access" {
  name_prefix = "${var.name_prefix}-s3-access-"
  description = "IAM policy for S3 bucket access"
  policy      = data.aws_iam_policy_document.s3_access.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-access-policy"
    Type = "IAMPolicy"
  })
}

# ==============================================================================
# IAM USER FOR GITHUB ACTIONS
# ==============================================================================

resource "aws_iam_user" "github_actions" {
  name = "${var.name_prefix}-github-actions"
  path = "/service/"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-github-actions-user"
    Type    = "ServiceUser"
    Purpose = "GitHubActions"
  })
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# Attach S3 access policy
resource "aws_iam_user_policy_attachment" "github_actions_s3" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# Policy for Secrets Manager access
data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.secrets_manager_arns
  }
}

resource "aws_iam_policy" "secrets_access" {
  name_prefix = "${var.name_prefix}-github-secrets-"
  description = "IAM policy for GitHub Actions to access secrets"
  policy      = data.aws_iam_policy_document.secrets_access.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-github-secrets-policy"
    Type = "IAMPolicy"
  })
}

# Attach secrets access policy
resource "aws_iam_user_policy_attachment" "github_actions_secrets" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
