# ==============================================================================
# VARIABLES FOR S3 MODULE
# ==============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for app assets"
  type        = bool
  default     = true
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_100, PriceClass_200)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_100", "PriceClass_200"], var.cloudfront_price_class)
    error_message = "CloudFront price class must be one of: PriceClass_All, PriceClass_100, PriceClass_200."
  }
}

variable "app_assets_lifecycle_enabled" {
  description = "Enable lifecycle management for app assets bucket"
  type        = bool
  default     = true
}

variable "testflight_builds_retention_days" {
  description = "Number of days to retain TestFlight builds"
  type        = number
  default     = 90

  validation {
    condition     = var.testflight_builds_retention_days >= 1 && var.testflight_builds_retention_days <= 365
    error_message = "TestFlight builds retention must be between 1 and 365 days."
  }
}
