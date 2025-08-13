# ==============================================================================
# DYNAMODB MODULE OUTPUTS
# ==============================================================================
# Output values for the DynamoDB module
# ==============================================================================

# ==============================================================================
# TABLE OUTPUTS
# ==============================================================================

output "live_conversations_table_name" {
  description = "Name of the live conversations DynamoDB table"
  value       = aws_dynamodb_table.live_conversations.name
}

output "live_conversations_table_arn" {
  description = "ARN of the live conversations DynamoDB table"
  value       = aws_dynamodb_table.live_conversations.arn
}

output "websocket_connections_table_name" {
  description = "Name of the WebSocket connections DynamoDB table"
  value       = aws_dynamodb_table.websocket_connections.name
}

output "websocket_connections_table_arn" {
  description = "ARN of the WebSocket connections DynamoDB table"
  value       = aws_dynamodb_table.websocket_connections.arn
}

output "session_context_table_name" {
  description = "Name of the session context DynamoDB table"
  value       = aws_dynamodb_table.session_context.name
}

output "session_context_table_arn" {
  description = "ARN of the session context DynamoDB table"
  value       = aws_dynamodb_table.session_context.arn
}

# ==============================================================================
# STREAM OUTPUTS
# ==============================================================================

output "live_conversations_stream_arn" {
  description = "ARN of the live conversations table stream (if enabled)"
  value       = var.enable_streams ? aws_dynamodb_table.live_conversations.stream_arn : null
}

output "live_conversations_stream_label" {
  description = "Stream label of the live conversations table (if enabled)"
  value       = var.enable_streams ? aws_dynamodb_table.live_conversations.stream_label : null
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "dynamodb_access_policy_arn" {
  description = "ARN of the IAM policy for DynamoDB access"
  value       = aws_iam_policy.dynamodb_access.arn
}

# ==============================================================================
# MONITORING OUTPUTS
# ==============================================================================

output "live_conversations_throttled_alarm_name" {
  description = "Name of the live conversations throttled requests alarm"
  value       = aws_cloudwatch_metric_alarm.live_conversations_throttled_requests.alarm_name
}

output "live_conversations_errors_alarm_name" {
  description = "Name of the live conversations system errors alarm"
  value       = aws_cloudwatch_metric_alarm.live_conversations_errors.alarm_name
}

output "websocket_connections_throttled_alarm_name" {
  description = "Name of the WebSocket connections throttled requests alarm"
  value       = aws_cloudwatch_metric_alarm.websocket_connections_throttled_requests.alarm_name
}

# ==============================================================================
# TABLE CONFIGURATION SUMMARY
# ==============================================================================

output "table_configuration_summary" {
  description = "Summary of DynamoDB table configurations"
  value = {
    live_conversations = {
      name         = aws_dynamodb_table.live_conversations.name
      billing_mode = aws_dynamodb_table.live_conversations.billing_mode
      hash_key     = aws_dynamodb_table.live_conversations.hash_key
      range_key    = aws_dynamodb_table.live_conversations.range_key
      ttl_enabled  = aws_dynamodb_table.live_conversations.ttl[0].enabled
      ttl_attribute = aws_dynamodb_table.live_conversations.ttl[0].attribute_name
      stream_enabled = var.enable_streams
    }
    websocket_connections = {
      name         = aws_dynamodb_table.websocket_connections.name
      billing_mode = aws_dynamodb_table.websocket_connections.billing_mode
      hash_key     = aws_dynamodb_table.websocket_connections.hash_key
      ttl_enabled  = aws_dynamodb_table.websocket_connections.ttl[0].enabled
      ttl_attribute = aws_dynamodb_table.websocket_connections.ttl[0].attribute_name
    }
    session_context = {
      name         = aws_dynamodb_table.session_context.name
      billing_mode = aws_dynamodb_table.session_context.billing_mode
      hash_key     = aws_dynamodb_table.session_context.hash_key
      range_key    = aws_dynamodb_table.session_context.range_key
      ttl_enabled  = aws_dynamodb_table.session_context.ttl[0].enabled
      ttl_attribute = aws_dynamodb_table.session_context.ttl[0].attribute_name
    }
  }
}
