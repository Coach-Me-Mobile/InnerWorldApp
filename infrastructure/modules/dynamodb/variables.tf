# ==============================================================================
# DYNAMODB MODULE VARIABLES
# ==============================================================================
# Input variables for the DynamoDB module
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
# DYNAMODB CONFIGURATION
# ==============================================================================

variable "billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or ON_DEMAND)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["PROVISIONED", "ON_DEMAND"], var.billing_mode)
    error_message = "Billing mode must be either PROVISIONED or ON_DEMAND."
  }
}

variable "enable_streams" {
  description = "Enable DynamoDB Streams for live conversations table"
  type        = bool
  default     = false
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB tables"
  type        = bool
  default     = true
}

# ==============================================================================
# SECURITY AND ENCRYPTION
# ==============================================================================

variable "kms_key_id" {
  description = "KMS key ID for DynamoDB encryption (if not specified, uses default key)"
  type        = string
  default     = null
}

# ==============================================================================
# PROVISIONED CAPACITY (only used if billing_mode = PROVISIONED)
# ==============================================================================

variable "live_conversations_read_capacity" {
  description = "Read capacity units for live conversations table"
  type        = number
  default     = 5
}

variable "live_conversations_write_capacity" {
  description = "Write capacity units for live conversations table"
  type        = number
  default     = 5
}

variable "websocket_connections_read_capacity" {
  description = "Read capacity units for WebSocket connections table"
  type        = number
  default     = 5
}

variable "websocket_connections_write_capacity" {
  description = "Write capacity units for WebSocket connections table"
  type        = number
  default     = 5
}

variable "session_context_read_capacity" {
  description = "Read capacity units for session context table"
  type        = number
  default     = 5
}

variable "session_context_write_capacity" {
  description = "Write capacity units for session context table"
  type        = number
  default     = 5
}

# ==============================================================================
# AUTO SCALING (only used if billing_mode = PROVISIONED)
# ==============================================================================

variable "enable_autoscaling" {
  description = "Enable auto scaling for DynamoDB tables"
  type        = bool
  default     = false
}

variable "autoscaling_target_value" {
  description = "Target utilization percentage for auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.autoscaling_target_value >= 20 && var.autoscaling_target_value <= 90
    error_message = "Auto scaling target value must be between 20 and 90."
  }
}

variable "autoscaling_min_capacity" {
  description = "Minimum capacity for auto scaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum capacity for auto scaling"
  type        = number
  default     = 100
}

# ==============================================================================
# TTL CONFIGURATION
# ==============================================================================

variable "live_conversations_ttl_hours" {
  description = "TTL for live conversation records in hours"
  type        = number
  default     = 24

  validation {
    condition     = var.live_conversations_ttl_hours >= 1 && var.live_conversations_ttl_hours <= 168
    error_message = "Live conversations TTL must be between 1 and 168 hours (1 week)."
  }
}

variable "websocket_connections_ttl_minutes" {
  description = "TTL for WebSocket connection records in minutes"
  type        = number
  default     = 30

  validation {
    condition     = var.websocket_connections_ttl_minutes >= 5 && var.websocket_connections_ttl_minutes <= 120
    error_message = "WebSocket connections TTL must be between 5 and 120 minutes."
  }
}

variable "session_context_ttl_hours" {
  description = "TTL for session context cache in hours"
  type        = number
  default     = 1

  validation {
    condition     = var.session_context_ttl_hours >= 1 && var.session_context_ttl_hours <= 24
    error_message = "Session context TTL must be between 1 and 24 hours."
  }
}

# ==============================================================================
# ALARMS
# ==============================================================================

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# ==============================================================================
# BACKUP CONFIGURATION
# ==============================================================================

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}
