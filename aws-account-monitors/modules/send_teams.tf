# Set up the SNS to send to teams :

# First lets see if we need a Teams lamba / setup for this level

# Create the lambda zip file
data "archive_file" "lambda" {
  count		= var.alerts.use_teams ? 1 : 0
  type		= "zip"
  source_file	= "../../modules/lambda_function.py"
  output_path	= "teams_lambda.zip"
}

# Define the Lambda function
resource "aws_lambda_function" "lambda_alert_to_teams" {
  count 	= var.alerts.use_teams ? 1 : 0
  filename      = "teams_lambda.zip"
  function_name = "alert_to_teams_lambda_function"
  role          = aws_iam_role.snsToLambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
      TEAMS_WEBHOOK_URL = var.alerts.teams_endpoint
    }
  }
}



# Create the SNS topic subscriptions
resource "aws_sns_topic_subscription" "topic_braodcast_subscription" {
  count		= var.alerts.use_teams ? 1 : 0
  protocol	= "lambda"
  endpoint	= aws_lambda_function.lambda_alert_to_teams[0].arn 
  topic_arn	= aws_sns_topic.cost_anomaly_updates.arn
}


