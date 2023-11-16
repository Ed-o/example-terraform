### ALB Load Blanacer alarms :

# lets see if we have ALB checks turned on overall and then check each one
locals {
  albs = {
    for alb_name, alb_config in var.albs :
    alb_name => alb_config
    if ((var.setup.enable_alb == "true") && (alb_config.enabled == "true"))
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_hosts_alarm_high" {
  for_each            = local.albs
  alarm_name          = "ALB-hosts-${each.value.threshold_high}"
  alarm_description   = "Alarm when ALB hosts drops below ${each.value.threshold_high}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "${each.value.threshold_high}"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["high"].arn ]

  dimensions = {
    LoadBalancer = "${each.value.alb_fullname}"
    TargetGroup = "${each.value.alb_target}"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_hosts_alarm_urgent" {
  for_each            = local.albs
  alarm_name          = "ALB-hosts-${each.value.threshold_urgent}"
  alarm_description   = "Alarm when ALB hosts drops below ${each.value.threshold_urgent}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "${each.value.threshold_urgent}"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["urgent"].arn ]

  dimensions = {
    LoadBalancer = "${each.value.alb_fullname}"
    TargetGroup = "${each.value.alb_target}"
  }
}

