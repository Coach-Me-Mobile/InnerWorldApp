# ==============================================================================
# LAMBDA MODULE OUTPUTS
# ==============================================================================
# Output values from the Lambda module
# ==============================================================================

# ==============================================================================
# LAMBDA FUNCTION OUTPUTS
# ==============================================================================

output "conversation_handler_function_name" {
  description = "Name of the conversation handler Lambda function"
  value       = aws_lambda_function.conversation_handler.function_name
}

output "conversation_handler_function_arn" {
  description = "ARN of the conversation handler Lambda function"
  value       = aws_lambda_function.conversation_handler.arn
}

output "conversation_handler_invoke_arn" {
  description = "Invoke ARN of the conversation handler Lambda function"
  value       = aws_lambda_function.conversation_handler.invoke_arn
}

output "health_check_function_name" {
  description = "Name of the health check Lambda function"
  value       = aws_lambda_function.health_check.function_name
}

output "health_check_function_arn" {
  description = "ARN of the health check Lambda function"
  value       = aws_lambda_function.health_check.arn
}

output "health_check_invoke_arn" {
  description = "Invoke ARN of the health check Lambda function"
  value       = aws_lambda_function.health_check.invoke_arn
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.name
}

# ==============================================================================
# REST API GATEWAY OUTPUTS
# ==============================================================================

output "rest_api_id" {
  description = "ID of the REST API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "rest_api_endpoint" {
  description = "REST API Gateway endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

output "rest_api_health_endpoint" {
  description = "Health check endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/health"
}

# ==============================================================================
# WEBSOCKET API GATEWAY OUTPUTS  
# ==============================================================================

output "websocket_api_id" {
  description = "ID of the WebSocket API Gateway"
  value       = aws_apigatewayv2_api.websocket.id
}

output "websocket_api_endpoint" {
  description = "WebSocket API Gateway endpoint URL"
  value       = "wss://${aws_apigatewayv2_api.websocket.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

# ==============================================================================
# CLOUDWATCH OUTPUTS
# ==============================================================================

output "conversation_handler_log_group_name" {
  description = "CloudWatch log group name for conversation handler"
  value       = aws_cloudwatch_log_group.conversation_handler.name
}

output "health_check_log_group_name" {
  description = "CloudWatch log group name for health check"
  value       = aws_cloudwatch_log_group.health_check.name
}

# ==============================================================================
# SUMMARY OUTPUTS
# ==============================================================================

output "lambda_functions_summary" {
  description = "Summary of deployed Lambda functions"
  value = {
    conversation_handler = {
      name        = aws_lambda_function.conversation_handler.function_name
      arn         = aws_lambda_function.conversation_handler.arn
      runtime     = aws_lambda_function.conversation_handler.runtime
      memory_size = aws_lambda_function.conversation_handler.memory_size
      timeout     = aws_lambda_function.conversation_handler.timeout
    }
    health_check = {
      name        = aws_lambda_function.health_check.function_name
      arn         = aws_lambda_function.health_check.arn
      runtime     = aws_lambda_function.health_check.runtime
      memory_size = aws_lambda_function.health_check.memory_size
      timeout     = aws_lambda_function.health_check.timeout
    }
  }
}

output "api_gateways_summary" {
  description = "Summary of API Gateway endpoints"
  value = {
    rest_api = {
      id       = aws_api_gateway_rest_api.main.id
      endpoint = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
      health   = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/health"
    }
    websocket_api = {
      id       = aws_apigatewayv2_api.websocket.id
      endpoint = "wss://${aws_apigatewayv2_api.websocket.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
    }
  }
}
