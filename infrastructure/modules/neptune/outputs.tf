# ==============================================================================
# NEPTUNE MODULE OUTPUTS
# ==============================================================================
# Output values for the Neptune module
# ==============================================================================

# ==============================================================================
# NEPTUNE CLUSTER OUTPUTS
# ==============================================================================

output "cluster_endpoint" {
  description = "Neptune cluster endpoint for read/write operations"
  value       = aws_neptune_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Neptune cluster reader endpoint for read-only operations"
  value       = aws_neptune_cluster.main.reader_endpoint
}

output "cluster_arn" {
  description = "ARN of the Neptune cluster"
  value       = aws_neptune_cluster.main.arn
}

output "cluster_id" {
  description = "ID of the Neptune cluster"
  value       = aws_neptune_cluster.main.id
}

output "cluster_port" {
  description = "Port number for Neptune cluster connections"
  value       = aws_neptune_cluster.main.port
}

# ==============================================================================
# NEPTUNE INSTANCE OUTPUTS
# ==============================================================================

output "instance_endpoints" {
  description = "List of Neptune instance endpoints"
  value       = aws_neptune_cluster_instance.cluster_instances[*].endpoint
}

output "instance_ids" {
  description = "List of Neptune instance IDs"
  value       = aws_neptune_cluster_instance.cluster_instances[*].id
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "subnet_group_name" {
  description = "Name of the Neptune subnet group"
  value       = aws_neptune_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Name of the Neptune parameter group"
  value       = aws_neptune_parameter_group.main.name
}

output "cluster_parameter_group_name" {
  description = "Name of the Neptune cluster parameter group"
  value       = aws_neptune_cluster_parameter_group.main.name
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "neptune_access_policy_arn" {
  description = "ARN of the IAM policy for Neptune access"
  value       = aws_iam_policy.neptune_access.arn
}

# ==============================================================================
# MONITORING OUTPUTS
# ==============================================================================

output "audit_log_group_name" {
  description = "Name of the CloudWatch log group for Neptune audit logs"
  value       = var.enable_audit_log ? aws_cloudwatch_log_group.neptune_audit[0].name : null
}

output "cpu_alarm_names" {
  description = "Names of CPU utilization CloudWatch alarms"
  value       = aws_cloudwatch_metric_alarm.cpu_utilization[*].alarm_name
}

output "memory_alarm_names" {
  description = "Names of memory utilization CloudWatch alarms"
  value       = aws_cloudwatch_metric_alarm.memory_utilization[*].alarm_name
}
