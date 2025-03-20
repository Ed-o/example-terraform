### Page Pull alarms :

# lets see if we have Page-Pull monitors enabled overall and then check each one
locals {
  pages = {
    for page_name, page_config in var.pagepull :
    page_name => page_config
    if ((var.setup.enable_pagepull == "true") && (page_config.enabled == "true"))
  }
}

resource "aws_synthetics_canary" "synthetics_canary" {
  ### Note - this part is not finished yet
  for_each = {
    # We will check in here to see if we should create the test canary else we will skip
    for pp_name, pp_config in local.pages :
    pp_name => pp_config
    if pp_config.create == "true"
  }
  name        	       = "${each.value.name}"
  artifact_s3_location = ""
  execution_role_arn   = "${each.value.role_arn}"
  handler              = "exports.handler"
  zip_file             = "synthetics_canary.zip"
  runtime_version      = "syn-nodejs-puppeteer-3.9"

  schedule {
    expression = "rate(0 minute)"
  }

}

resource "aws_cloudwatch_metric_alarm" "page_pull_main" {
  for_each            = local.pages
  alarm_name          = "${each.value.name}"
  alarm_description   = "Alarm when page will not load : ${each.value.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "Failed requests"
  namespace           = "CloudWatchSynthetics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["urgent"].arn ]

  dimensions = {
    CanaryName    = "${each.value.synthetics_canary}"
  }
}


