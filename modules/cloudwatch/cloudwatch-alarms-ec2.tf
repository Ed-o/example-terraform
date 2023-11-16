### First EC2 alarms :

# lets see if we have EC2 servers enabled overall and then check each one
locals {
  servers = {
    for server_name, server_config in var.servers :
    server_name => server_config
    if ((var.setup.enable_ec2 == "true") && (server_config.enabled == "true"))
  }
}


resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarms" {
  for_each = local.servers

  alarm_name          = "EC2 CPU ${each.value.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = each.value.cpu_threshold
  actions_enabled     = true
  alarm_description   = "Alarm when ${each.value.name} CPU exceeds ${each.value.cpu_threshold}%"
  alarm_actions       = [ aws_sns_topic.alert_topic["high"].arn ]

  dimensions = {
    InstanceId = each.value.id
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_statuscheck_alarms" {
  for_each = local.servers

  alarm_name          = "EC2 StatusCheck ${each.value.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1
  actions_enabled     = true
  alarm_description   = "Alarm when ${each.value.name} fails a server Ec2 Status Check"
  alarm_actions       = [ aws_sns_topic.alert_topic["high"].arn ]

  dimensions = {
    InstanceId = each.value.id
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_networkIn_alarms" {
  for_each = local.servers

  alarm_name          = "EC2 Network In ${each.value.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  threshold           = each.value.net_threshold
  actions_enabled     = true
  alarm_description   = "Alarm when ${each.value.name} Network In exceeds ${each.value.net_threshold}"
  alarm_actions       = [ aws_sns_topic.alert_topic["medium"].arn ]

  dimensions = {
    InstanceId = each.value.id
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_networkOut_alarms" {
  for_each = local.servers

  alarm_name          = "EC2 Network Out ${each.value.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  threshold           = each.value.net_threshold
  actions_enabled     = true
  alarm_description   = "Alarm when ${each.value.name} Network Out exceeds ${each.value.net_threshold}"
  alarm_actions       = [ aws_sns_topic.alert_topic["medium"].arn ]

  dimensions = {
    InstanceId = each.value.id
  }
}

