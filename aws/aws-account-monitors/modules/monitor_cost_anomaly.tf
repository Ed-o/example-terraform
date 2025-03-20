# Setup monitor for cost anomaly

resource "aws_ce_anomaly_monitor" "anomaly_monitor" {
  count			= var.values.cost_anomaly_enabled ? 1: 0
  name			= "AWSServiceMonitor"
  monitor_type		= "DIMENSIONAL"
  monitor_dimension	= "SERVICE"
}

resource "aws_ce_anomaly_subscription" "realtime_subscription" {
  count			= var.values.cost_anomaly_enabled ? 1: 0
  name      = "RealtimeAnomalySubscription"
  frequency = "IMMEDIATE"
  threshold_expression {
    or {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
        values        = [var.values.cost_anomaly_amount_percent]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
    or {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = [var.values.cost_anomaly_amount_absolute]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }
  monitor_arn_list = [
    aws_ce_anomaly_monitor.anomaly_monitor[0].arn,
  ]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.alert_topic["high"].arn
  }
#  depends_on = [
#    aws_sns_topic_policy.default,
#  ]
}

