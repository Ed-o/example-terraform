# Alert levels and where to send them :

resource "aws_sns_topic" "alert_topic" {
  for_each = var.alerts
  name = "Monitoring-Alerts-${each.value.name}"
  delivery_policy = jsonencode(
  {
    http = {
      defaultHealthyRetryPolicy    = {
        backoffFunction    = "linear",
        maxDelayTarget     = 20,
        minDelayTarget     = 20,
        numMaxDelayRetries = 2,
        numMinDelayRetries = 1,
        numNoDelayRetries  = 1,
        numRetries         = 5,
      },
      disableSubscriptionOverrides = true,
    }
  })
  display_name = "Product"
  http_failure_feedback_role_arn = var.logging.failure_feedback_role_arn
  http_success_feedback_role_arn = var.logging.success_feedback_role_arn
  http_success_feedback_sample_rate = var.logging.success_feedback_sample_rate
  lambda_failure_feedback_role_arn = var.logging.failure_feedback_role_arn
  lambda_success_feedback_role_arn = var.logging.success_feedback_role_arn
  lambda_success_feedback_sample_rate = var.logging.success_feedback_sample_rate
  tags = {
    method = "teams"
    teams_url = "${each.value.teams_url}"
  }
}


# First lets see if we need a Teams lamba / setup for this level 

# Create the lambda zip file
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "teams_lambda.zip"
}

# Define the Lambda function
resource "aws_lambda_function" "lambda_alert_to_teams" {
  filename      = "teams_lambda.zip"
  function_name = "alert_to_teams_lambda_function"
  role          = aws_iam_role.snsToLambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
}



# Create the SNS topic subscriptions
resource "aws_sns_topic_subscription" "topic_braodcast_subscription" {
  for_each = aws_sns_topic.alert_topic

  protocol = "lambda"
  endpoint = aws_lambda_function.lambda_alert_to_teams.arn
  topic_arn = each.value.arn
}


