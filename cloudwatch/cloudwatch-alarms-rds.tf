### RDS alarms :

# lets see if we have RDS enabled overall and then check each one
locals {
  databases = {
    for db_name, db_config in var.databases :
    db_name => db_config
    if ((var.setup.enable_rds == "true") && (db_config.enabled == "true"))
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_alarm" {
  for_each = local.databases

  alarm_name          = "rds-cpu-${each.value.short_name}"
  alarm_description   = "Alarm when RDS CPU utilization exceeds ${each.value.cpu_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${each.value.cpu_threshold}"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["high"].arn ]

  dimensions = {
    DBInstanceIdentifier = each.value.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_alarm" {
  for_each = local.databases

  alarm_name          = "rds-connections-${each.value.short_name}"
  alarm_description   = "Alarm when RDS Connections exceed ${each.value.connection_threshold}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "${each.value.connection_threshold}"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["medium"].arn ]

  dimensions = {
    DBInstanceIdentifier = each.value.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_disk_space_alarm" {
  for_each = {
    # We will check in here to see if there is a disk threshold else we will skip
    for data_name, data_config in local.databases :
    data_name => data_config
    if data_config.storage_threshold > 0
  }
  alarm_name          = "rds-diskspace-${each.value.short_name}"
  alarm_description   = "Alarm when RDS disk space usage goes below ${each.value.storage_threshold}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "${each.value.storage_threshold}"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["high"].arn  ]
  dimensions = {
    DBInstanceIdentifier = each.value.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_memory_alarm" {
  for_each            = local.databases
  alarm_name          = "rds-memory-${each.value.short_name}"
  alarm_description   = "Alarm when RDS free memory goes below ${each.value.mem_threshold}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "${each.value.mem_threshold}"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["medium"].arn  ]
  dimensions = {
    DBInstanceIdentifier = each.value.name
  }
}

