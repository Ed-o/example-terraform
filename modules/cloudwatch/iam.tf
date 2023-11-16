# IAM Security items needed :


# Define the IAM policy for the Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:ListTagsForResource"
        ]
        Resource = "arn:aws:sns:*:*:*"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.snsToLambda.name
}

# and this one allows the SNS to call the Lambda and run it :

resource "aws_iam_policy" "sns_invoke_policy" {
  name        = "sns_invoke_policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for sns_topic in aws_sns_topic.alert_topic:
      {
        # Sid = "AllowSNSInvoke"
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = aws_lambda_function.lambda_alert_to_teams.arn
        Condition = {
          ArnEquals = {
            "AWS:SourceArn" = sns_topic.arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "sns_invoke_policy_attachment" {
  name       = "sns_invoke_policy_attachment"
  policy_arn = aws_iam_policy.sns_invoke_policy.arn
  roles      = [ aws_iam_role.snsToLambda.name ]
}

resource "aws_lambda_permission" "with_sns" {
  for_each      = aws_sns_topic.alert_topic
  # statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_alert_to_teams.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${each.value.arn}"
}

resource "aws_iam_role" "snsToLambda" {
  name = "iam_for_lambda_with_sns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
