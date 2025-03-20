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
    # The cost_anomaly spots rises in prices for items
    cost_anomaly_enabled 		= true
    cost_anomaly_amount_percent		= "10"
    cost_anomaly_amount_absolute	= "100"

    # The budget lets you know if it looks like it will go over that amount
    budget_enabled			= true
    budget_threshold			= "100"
  }
}

variable "alerts" {
  type = map
  default = {
    low = {
      name = "low"
      teams_enabled = true
      teams_url = "https://companyname.webhook.office.com/webhookb2/987654321/IncomingWebhook/987654321"
      email_enabled = false
      email_addr = "admin_email@company.com"
      sms_enabled = false
      sms_addr = "+353865555555"
    }
    medium = {
      name = "medium"
      teams_enabled = true
      teams_url = "https://companyname.webhook.office.com/webhookb2/987654321/IncomingWebhook/987654321"
      email_enabled = false
      email_addr = "admin_email@company.com"
      sms_enabled = false
      sms_addr = "+353865555555"
    }
    high = {
      name = "high"
      teams_enabled = true
      teams_url = "https://companyname.webhook.office.com/webhookb2/987654321/IncomingWebhook/987654321"
      email_enabled = false
      email_addr = "admin_email@company.com"
      sms_enabled = false
      sms_addr = "+353865555555"
    }
    urgent = {
      name = "urgent"
      teams_enabled = true
      teams_url = "https://companyname.webhook.office.com/webhookb2/987654321/IncomingWebhook/987654321"
      email_enabled = false
      email_addr = "admin_email@company.com"
      sms_enabled = false
      sms_addr = "+353865555555"
    }
  }
}

