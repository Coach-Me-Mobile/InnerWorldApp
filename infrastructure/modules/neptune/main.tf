# ==============================================================================
# NEPTUNE MODULE
# ==============================================================================
# AWS Neptune Graph Database for InnerWorld GraphRAG storage
# Manages user conversation history, user context, and relationship graphs
# ==============================================================================

# ==============================================================================
# NEPTUNE SUBNET GROUP
# ==============================================================================

resource "aws_neptune_subnet_group" "main" {
  name       = "${var.name_prefix}-neptune-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-neptune-subnet-group"
    Type = "NeptuneSubnetGroup"
  })
}

# ==============================================================================
# NEPTUNE PARAMETER GROUP
# ==============================================================================

resource "aws_neptune_parameter_group" "main" {
  family = "neptune1.3"
  name   = "${var.name_prefix}-neptune-params"

  parameter {
    name  = "neptune_enable_audit_log"
    value = var.enable_audit_log ? "1" : "0"
  }

  parameter {
    name  = "neptune_query_timeout"
    value = tostring(var.query_timeout_ms)
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-neptune-parameter-group"
    Type = "NeptuneParameterGroup"
  })
}

# ==============================================================================
# NEPTUNE CLUSTER PARAMETER GROUP
# ==============================================================================

resource "aws_neptune_cluster_parameter_group" "main" {
  family = "neptune1.3"
  name   = "${var.name_prefix}-neptune-cluster-params"

  parameter {
    name  = "neptune_enable_audit_log"
    value = var.enable_audit_log ? "1" : "0"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-neptune-cluster-parameter-group"
    Type = "NeptuneClusterParameterGroup"
  })
}

# ==============================================================================
# NEPTUNE CLUSTER
# ==============================================================================

resource "aws_neptune_cluster" "main" {
  cluster_identifier           = "${var.name_prefix}-neptune-cluster"
  engine                       = "neptune"
  engine_version               = var.engine_version
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  # Security and networking
  neptune_subnet_group_name = aws_neptune_subnet_group.main.name
  vpc_security_group_ids    = var.security_group_ids

  # Parameter groups
  neptune_cluster_parameter_group_name = aws_neptune_cluster_parameter_group.main.name

  # Authentication
  iam_database_authentication_enabled = var.iam_auth_enabled

  # Encryption
  storage_encrypted = true
  kms_key_arn       = var.kms_key_id

  # Deletion protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "dev" ? null : "${var.name_prefix}-neptune-final-snapshot"

  # Backup settings
  copy_tags_to_snapshot = true

  # Enable logging
  enable_cloudwatch_logs_exports = ["audit"]

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-neptune-cluster"
    Type    = "NeptuneCluster"
    Purpose = "GraphRAG"
  })

  depends_on = [
    aws_neptune_subnet_group.main,
    aws_neptune_cluster_parameter_group.main
  ]
}

# ==============================================================================
# NEPTUNE INSTANCES
# ==============================================================================

resource "aws_neptune_cluster_instance" "cluster_instances" {
  count              = var.instance_count
  identifier         = "${var.name_prefix}-neptune-instance-${count.index + 1}"
  cluster_identifier = aws_neptune_cluster.main.id
  instance_class     = var.instance_class
  engine             = "neptune"
  engine_version     = var.engine_version

  neptune_parameter_group_name = aws_neptune_parameter_group.main.name

  # Note: Performance insights not supported for Neptune instances

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-neptune-instance-${count.index + 1}"
    Type    = "NeptuneInstance"
    Purpose = "GraphRAG"
  })

  depends_on = [aws_neptune_cluster.main]
}

# ==============================================================================
# CLOUDWATCH LOG GROUP FOR AUDIT LOGS
# ==============================================================================

resource "aws_cloudwatch_log_group" "neptune_audit" {
  count             = var.enable_audit_log ? 1 : 0
  name              = "/aws/neptune/${var.name_prefix}/audit"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-neptune-audit-logs"
    Type = "CloudWatchLogGroup"
  })
}

# ==============================================================================
# CLOUDWATCH ALARMS FOR NEPTUNE MONITORING
# ==============================================================================

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.instance_count

  alarm_name          = "${var.name_prefix}-neptune-cpu-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Neptune"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors Neptune CPU utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_neptune_cluster_instance.cluster_instances[count.index].identifier
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-neptune-cpu-alarm-${count.index + 1}"
    Type = "CloudWatchAlarm"
  })
}

# Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  count = var.instance_count

  alarm_name          = "${var.name_prefix}-neptune-freeable-memory-${count.index + 1}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/Neptune"
  period              = "300"
  statistic           = "Average"
  threshold           = "268435456" # 256 MB in bytes
  alarm_description   = "This metric monitors Neptune freeable memory"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_neptune_cluster_instance.cluster_instances[count.index].identifier
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-neptune-memory-alarm-${count.index + 1}"
    Type = "CloudWatchAlarm"
  })
}

# ==============================================================================
# IAM POLICY FOR LAMBDA ACCESS TO NEPTUNE
# ==============================================================================

data "aws_iam_policy_document" "neptune_access" {
  statement {
    effect = "Allow"

    actions = [
      "neptune-db:*"
    ]

    resources = [
      aws_neptune_cluster.main.arn,
      "${aws_neptune_cluster.main.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "neptune_access" {
  name_prefix = "${var.name_prefix}-neptune-access-"
  description = "IAM policy for Lambda functions to access Neptune"
  policy      = data.aws_iam_policy_document.neptune_access.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-neptune-access-policy"
    Type = "IAMPolicy"
  })
}
