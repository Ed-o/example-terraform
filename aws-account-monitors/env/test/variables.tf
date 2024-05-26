variable "setup" {
  type = map
  default = {
    environment         = "eu-test"
    name                = "eu-test"
    creator             = "terraform"
    account             = "987654321987"
    region		= "eu-west-1"
    resource_tags	= ""
  }
}

variable "values" {
  type = map
  default = {
    raise_amount_percent	= "10"
    raise_amount_absolute	= "1000"
  }
}

variable "alerts" {
  type        = map
  default     = {
    use_pagerduty = false
    pagerduty_endpoint = ""
    use_teams = false
    teams_endpoint = "https://compnayname.webhook.office.com/webhookb2/987654321/IncomingWebhook/987654321"
    use_emails = false
  }
}

variable "emails" {
  type = list(string)
  default = [
    "email@companyname.changethis"
  ]
}
