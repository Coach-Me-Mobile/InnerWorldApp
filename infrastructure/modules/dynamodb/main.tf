# ==============================================================================
# DYNAMODB MODULE
# ==============================================================================
# DynamoDB tables for InnerWorld real-time conversation storage
# Handles live conversations, WebSocket connections, and session context
# ==============================================================================

# ==============================================================================
# LIVE CONVERSATIONS TABLE
# ==============================================================================
# Stores real-time conversation messages during 20-minute sessions
# TTL auto-deletes after processing to Neptune

resource "aws_dynamodb_table" "live_conversations" {
  name             = "${var.name_prefix}-live-conversations"
  billing_mode     = "PAY_PER_REQUEST" # Auto-scales for conversation bursts
  hash_key         = "conversation_id"
  range_key        = "message_sequence"
  stream_enabled   = var.enable_streams
  stream_view_type = var.enable_streams ? "NEW_AND_OLD_IMAGES" : null

  # Attributes
  attribute {
    name = "conversation_id"
    type = "S"
  }

  attribute {
    name = "message_sequence"
    type = "N"
  }

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  # GSI for session-based queries
  global_secondary_index {
    name            = "SessionIndex"
    hash_key        = "session_id"
    range_key       = "message_sequence"
    projection_type = "ALL"
  }

  # GSI for user-based queries
  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "user_id"
    range_key       = "conversation_id"
    projection_type = "ALL"
  }

  # TTL for automatic cleanup after processing
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-live-conversations"
    Type    = "DynamoDBTable"
    Purpose = "LiveConversationStorage"
    TTL     = "24hours"
  })
}

# ==============================================================================
# WEBSOCKET CONNECTIONS TABLE
# ==============================================================================
# Tracks active WebSocket connections for real-time message delivery

resource "aws_dynamodb_table" "websocket_connections" {
  name         = "${var.name_prefix}-websocket-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connection_id"

  # Attributes
  attribute {
    name = "connection_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "session_id"
    type = "S"
  }

  # GSI for user-based connection lookup
  global_secondary_index {
    name            = "UserConnectionsIndex"
    hash_key        = "user_id"
    range_key       = "connection_id"
    projection_type = "ALL"
  }

  # GSI for session-based connection lookup
  global_secondary_index {
    name            = "SessionConnectionsIndex"
    hash_key        = "session_id"
    range_key       = "connection_id"
    projection_type = "ALL"
  }

  # TTL for automatic connection cleanup
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-websocket-connections"
    Type    = "DynamoDBTable"
    Purpose = "WebSocketConnectionTracking"
    TTL     = "30minutes"
  })
}

# ==============================================================================
# SESSION CONTEXT CACHE TABLE
# ==============================================================================
# Caches Neptune GraphRAG context for fast conversation responses

resource "aws_dynamodb_table" "session_context" {
  name         = "${var.name_prefix}-session-context"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "session_id"

  # Attributes
  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  # GSI for time-based context cleanup
  global_secondary_index {
    name            = "CreatedAtIndex"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "KEYS_ONLY"
  }

  # TTL for automatic context cleanup (1 hour after session end)
  ttl {
    attribute_name = "context_expires_at"
    enabled        = true
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-session-context"
    Type    = "DynamoDBTable"
    Purpose = "GraphRAGContextCache"
    TTL     = "1hour"
  })
}

# ==============================================================================
# CLOUDWATCH ALARMS FOR DYNAMODB MONITORING
# ==============================================================================

# Live Conversations Table Alarms
resource "aws_cloudwatch_metric_alarm" "live_conversations_throttled_requests" {
  alarm_name          = "${var.name_prefix}-live-conversations-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB throttled requests"
  alarm_actions       = var.alarm_actions

  dimensions = {
    TableName = aws_dynamodb_table.live_conversations.name
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-live-conversations-throttled-alarm"
    Type = "CloudWatchAlarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "live_conversations_errors" {
  alarm_name          = "${var.name_prefix}-live-conversations-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB system errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    TableName = aws_dynamodb_table.live_conversations.name
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-live-conversations-errors-alarm"
    Type = "CloudWatchAlarm"
  })
}

# WebSocket Connections Table Alarms
resource "aws_cloudwatch_metric_alarm" "websocket_connections_throttled_requests" {
  alarm_name          = "${var.name_prefix}-websocket-connections-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors WebSocket connections table throttled requests"
  alarm_actions       = var.alarm_actions

  dimensions = {
    TableName = aws_dynamodb_table.websocket_connections.name
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-websocket-connections-throttled-alarm"
    Type = "CloudWatchAlarm"
  })
}

# ==============================================================================
# IAM POLICY FOR LAMBDA ACCESS TO DYNAMODB
# ==============================================================================

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]

    resources = [
      aws_dynamodb_table.live_conversations.arn,
      aws_dynamodb_table.websocket_connections.arn,
      aws_dynamodb_table.session_context.arn,
      "${aws_dynamodb_table.live_conversations.arn}/index/*",
      "${aws_dynamodb_table.websocket_connections.arn}/index/*",
      "${aws_dynamodb_table.session_context.arn}/index/*"
    ]
  }

  # DynamoDB Streams access (if enabled)
  dynamic "statement" {
    for_each = var.enable_streams ? [1] : []
    content {
      effect = "Allow"

      actions = [
        "dynamodb:DescribeStream",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:ListStreams"
      ]

      resources = [
        "${aws_dynamodb_table.live_conversations.arn}/stream/*"
      ]
    }
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name_prefix = "${var.name_prefix}-dynamodb-access-"
  description = "IAM policy for Lambda functions to access DynamoDB tables"
  policy      = data.aws_iam_policy_document.dynamodb_access.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dynamodb-access-policy"
    Type = "IAMPolicy"
  })
}
