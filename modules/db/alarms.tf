locals {
  alarms_enabled         = module.this.enabled && var.alarms_enabled
  replica_alarms_enabled = local.alarms_enabled && var.create_replica
  # CPUCreditBalance only exists on burstable instance classes
  burstable = length(regexall("^db\\.t", var.instance_class)) > 0

  cpu_credit_alarm_instances = local.burstable ? merge(
    { primary = module.rds_instance.instance_id },
    local.replica_alarms_enabled ? { replica = module.rds_replica.instance_id } : {}
  ) : {}
}

// Primary instance

resource "aws_cloudwatch_metric_alarm" "primary_cpu" {
  count = local.alarms_enabled ? 1 : 0

  alarm_name          = "${module.this.id}-primary-cpu-high"
  alarm_description   = "RDS primary CPU utilisation is high"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = module.rds_instance.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.alarm_primary_cpu_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  tags = module.this.tags
}

resource "aws_cloudwatch_metric_alarm" "primary_connections" {
  count = local.alarms_enabled ? 1 : 0

  alarm_name          = "${module.this.id}-primary-connections-high"
  alarm_description   = "RDS primary connection count is high"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  dimensions          = { DBInstanceIdentifier = module.rds_instance.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.alarm_database_connections_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  tags = module.this.tags
}

// Replica instance

resource "aws_cloudwatch_metric_alarm" "replica_cpu" {
  count = local.replica_alarms_enabled ? 1 : 0

  alarm_name          = "${module.this.id}-replica-cpu-high"
  alarm_description   = "RDS replica CPU utilisation is high"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = module.rds_replica.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.alarm_replica_cpu_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  tags = module.this.tags
}

resource "aws_cloudwatch_metric_alarm" "replica_read_latency" {
  count = local.replica_alarms_enabled ? 1 : 0

  alarm_name          = "${module.this.id}-replica-read-latency-high"
  alarm_description   = "RDS replica read latency is high"
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  dimensions          = { DBInstanceIdentifier = module.rds_replica.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.alarm_replica_read_latency_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  tags = module.this.tags
}

resource "aws_cloudwatch_metric_alarm" "replica_connections" {
  count = local.replica_alarms_enabled ? 1 : 0

  alarm_name          = "${module.this.id}-replica-connections-high"
  alarm_description   = "RDS replica connection count is high"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  dimensions          = { DBInstanceIdentifier = module.rds_replica.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.alarm_database_connections_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  tags = module.this.tags
}

// Burstable instances (primary and replica)

resource "aws_cloudwatch_metric_alarm" "cpu_credit_balance" {
  for_each = local.alarms_enabled ? local.cpu_credit_alarm_instances : {}

  alarm_name          = "${module.this.id}-${each.key}-cpu-credits-low"
  alarm_description   = "RDS ${each.key} CPU credit balance is running low"
  namespace           = "AWS/RDS"
  metric_name         = "CPUCreditBalance"
  dimensions          = { DBInstanceIdentifier = each.value }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "LessThanThreshold"
  threshold           = var.alarm_cpu_credit_balance_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  tags = module.this.tags
}
