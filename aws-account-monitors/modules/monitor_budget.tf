# Keep an eye on the monthly budget numbers

resource "aws_cloudwatch_metric_alarm" "account_billing_alarm" {
  alarm_name          = "AWS Billing Alarm"
  alarm_description   = "Triggers when the monthly cost goes over threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "28800"
  statistic           = "Maximum"
  threshold           = var.values.budget_threshold
  alarm_actions       = [ aws_sns_topic.alert_topic["high"].arn ]
  datapoints_to_alarm = null
}

