# SNS setup

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "cost_anomaly_updates" {
  name              = "CostAnomalyUpdates"
  kms_master_key_id = "alias/aws/sns"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })
}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  count     = var.alerts.use_emails ? length(var.emails) : 0
  topic_arn = aws_sns_topic.cost_anomaly_updates.arn
  protocol  = "email"
  endpoint  = var.emails[count.index]
}

resource "aws_sns_topic_subscription" "pagerduty" {
  count                  = var.alerts.use_pagerduty ? 1 : 0
  endpoint               = var.alerts.pagerduty_endpoint
  endpoint_auto_confirms = true
  protocol               = "https"
  topic_arn              = aws_sns_topic.cost_anomaly_updates.arn
}






