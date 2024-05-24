variable "setup" {
  type = map
  default = {
    name = "cloudwatch"
    environment = "test"
    creator = "terraform"
    account = "987654321"

    enable_ec2 = false
    enable_alb = true
    enable_rds = true
    enable_reddis = true
    enable_pagepull = true
  }
}


variable "network_settings" {
  type = map
  default = {
    region = "eu-west-1"
    domain_name = "test.companyname.com"
  }
}

variable "albs" {
  type = map
  default = {
    alb01 = {
      enabled = "true"
      alb_name = "production-lb"
      alb_fullname = "app/product/987654321987654321"
      alb_target = "targetgroup/tg-product/987654321987654321"
      threshold_high = "2"
      threshold_urgent = "1"
    }
  }
}

variable "servers" {
  type = map
  default = {
    server01 = {
      name = "product-web-01"
      enabled = "true"
      id = "i-03" 
      cpu_threshold = 80
      net_threshold = 200000000
    }
    server02 = {
      name = "product-web-02"
      enabled = "true"
      id = "i-01"
      cpu_threshold = 80
      net_threshold = 200000000
    }
    server03 = {
      name = "product-web-03"
      enabled = "true"
      id = "i-07"
      cpu_threshold = 80
      net_threshold = 200000000
    }
    server04 = {
      name = "product-cron"
      enabled = "true"
      id = "i-05" 
      cpu_threshold = 80
      net_threshold = 100000000
    }
    server05 = {
      name = "bastion"
      enabled = "true"
      id = "i-04"
      cpu_threshold = 80
      net_threshold = 20000000
    }
  }
}

variable "databases" {
  type = map
  default = {
    db01 = {
      name = "platform-mysql-01"
      enabled = "true"
      cpu_threshold = 60
      connection_threshold = 20
      mem_threshold = 300000000
      storage_threshold = 0
      short_name = "platform-mysql-01"
    }
    db02 = {
      name = "platform-mysql-02"
      enabled = "true"
      cpu_threshold = 60
      connection_threshold = 20
      mem_threshold = 500000000
      storage_threshold = 0
      short_name = "platform-mysql-02"
    }
    db03 = {
      name = "platform-mysql-03"
      enabled = "true"
      cpu_threshold = 60
      connection_threshold = 20
      mem_threshold = 500000000
      storage_threshold = 0
      short_name = "platform-mysql-03"
    }
  }
}

variable "reddis" {
  type = map
  default = {
    reddis01 = {
      name = "redis"
      enabled = "true"
      cpu_threshold = 40
    }
    reddis02 = {
      name = "redis-002"
      enabled = "false"
      cpu_threshold = 40
    }
    reddis03 = {
      name = "redis-003"
      enabled = "false"
      cpu_threshold = 40
    }
  }
}

variable "pagepull" {
  type = map
  default = {
    pp01 = {
      name = "main-page"
      enabled = "true"
      url = ""
      create = "false" 
      synthetics_canary = "website-test"
      threshold_fail = "2"
      threshold_time = "180"
      speed = "60"
      role_arn = "arn:aws:iam::987654321:role/service-role/CloudWatchSyntheticsRole-prod-website-test-b0d-e83b987654321"
      s3_store = "s3://cw-syn-results-987654321-eu-west-1/canary/eu-west-1/prod-website-test-b0d-e83b987654321"
    }
  }
}

variable "backups" {
  type = map
  default = {
    backup01 = {
      name = "backup-jobs"
      enabled = "true"
    }
  }
}

variable "logging" {
  type = map
  default = {
    failure_feedback_role_arn = "arn:aws:iam::987654321:role/SNSFailureFeedback"
    success_feedback_role_arn = "arn:aws:iam::987654321:role/SNSSuccessFeedback"
    success_feedback_sample_rate = 100
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










