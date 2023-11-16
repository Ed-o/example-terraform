### Reddis alarms :

# lets see if we have Reddis enabled overall and then check each one
locals {
  reddis = {
    for red_name, red_config in var.reddis :
    red_name => red_config
    if ((var.setup.enable_reddis == "true") && (red_config.enabled == "true"))
  }
}

resource "aws_cloudwatch_metric_alarm" "reddis_cpu_alarm" {
  for_each = local.reddis

  alarm_name          = "reddis-cpu-${each.value.name}"
  alarm_description   = "Alarm when Reddis CPU utilization exceeds ${each.value.cpu_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"
  threshold           = "${each.value.cpu_threshold}"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["high"].arn ]

  dimensions = {
    CacheClusterId = each.value.name
  }
}


