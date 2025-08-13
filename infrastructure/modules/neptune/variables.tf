# ==============================================================================
# NEPTUNE MODULE VARIABLES
# ==============================================================================
# Input variables for the Neptune module
# ==============================================================================

# ==============================================================================
# GENERAL CONFIGURATION
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

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================

variable "subnet_ids" {
  description = "List of subnet IDs for Neptune subnet group (should be database subnets)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for Neptune cluster"
  type        = list(string)
}

# ==============================================================================
# NEPTUNE CLUSTER CONFIGURATION
# ==============================================================================

variable "engine_version" {
  description = "Neptune engine version"
  type        = string
  default     = "1.3.0.0"
}

variable "instance_class" {
  description = "Neptune instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of Neptune instances in the cluster"
  type        = number
  default     = 1
}

# ==============================================================================
# BACKUP AND MAINTENANCE
# ==============================================================================

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection for the Neptune cluster"
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

# ==============================================================================
# SECURITY AND ENCRYPTION
# ==============================================================================

variable "iam_auth_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if not specified, uses default key)"
  type        = string
  default     = null
}

# ==============================================================================
# PERFORMANCE AND MONITORING
# ==============================================================================

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

# ==============================================================================
# NEPTUNE SPECIFIC PARAMETERS
# ==============================================================================

variable "enable_audit_log" {
  description = "Enable Neptune audit logging"
  type        = bool
  default     = true
}

variable "query_timeout_ms" {
  description = "Query timeout in milliseconds"
  type        = number
  default     = 120000
}

# ==============================================================================
# LOGGING
# ==============================================================================

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

# ==============================================================================
# ALARMS
# ==============================================================================

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}
