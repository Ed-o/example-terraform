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

variable "emails" {
  type        = list(any)
  description = "List of email addresses to notify"
  default = ["ed.none.none"]
}

variable "raise_amount_percent" {
  type        = string
  description = "An Expression object used to specify the anomalies that you want to generate alerts for. The precentage service cost increase than the expected"
  default = "10"
}

variable "raise_amount_absolute" {
  type        = string
  description = "The Absolut increase in USD to trigger the detector. (ANOMALY_TOTAL_IMPACT_ABSOLUTE)"
  default = "100"
}

variable "create_pagerduty" {
  type        = bool
  default     = false
  description = "Set to true in order to send notifications to PagerDuty"
}

variable "pagerduty_endpoint" {
  description = "The PagerDuty HTTPS endpoint where SNS notifications will be sent to"
  type        = string
}

