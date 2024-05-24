# Setup AWS WAF (if required)

# These are Office / Clinc locations
resource "aws_wafv2_ip_set" "waf_ip_set01" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.aws_waf_enabled) ? 1 : 0
  name               = "Office-Locations"
  description        = "Office or clinic locations"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["1.1.1.1/32"]
  tags = {
    Name = "waf-rules"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "waf"
  }
}

# These are Uptime Robot IPs for IPV4
resource "aws_wafv2_ip_set" "waf_ip_set02" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.aws_waf_enabled) ? 1 : 0
  name               = "uptime-robot-ipv4"
  description        = "Uptime robot"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["1.1.1.1/32"]
  tags = {
    Name = "waf-rules"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "waf"
  }
}

# These are Uptime Robot IPs for IPV6
resource "aws_wafv2_ip_set" "waf_ip_set03" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.aws_waf_enabled) ? 1 : 0
  name               = "uptime-robot-ipv6"
  description        = "Uptime robot"
  scope              = "REGIONAL"
  ip_address_version = "IPV6"
  addresses          = ["9999:8888:777::43/128"]
  tags = {
    Name = "waf-rules"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "waf"
  }
}

# These are Strip API calls
resource "aws_wafv2_ip_set" "waf_ip_set04" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.aws_waf_enabled) ? 1 : 0
  name               = "WebHook"
  description        = "API Calls"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["1.1.1.1/32"]
  tags = {
    Name = "waf-rules"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "waf"
  }
}

resource "aws_wafv2_ip_set" "waf_ip_set05" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.aws_waf_enabled) ? 1 : 0
  name               = "ExternalTeam"
  description        = "External Team"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["1.1.1.1/32"]

  tags = {
    Name = "waf-rules"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "waf"
  }
}

####################

# Create a WAF WebACL
resource "aws_wafv2_web_acl" "waf_acl" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.aws_waf_enabled) ? 1 : 0
  name        = "waf-acl-${var.setup.environment}"
  description = "WAF"
  scope	      = "REGIONAL"
  default_action {
    allow {}
  }

### Rule-04 : Allow Authenticated users
  rule {
    name      = "allow-authenticated-users"
    priority  = 4
    action {
      allow {}
    }
    statement {
      byte_match_statement {
        field_to_match {
          single_header {
            name = "product_session"
          }
        }
        positional_constraint = "EXACTLY"
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        search_string        = "product_session"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule04"
      sampled_requests_enabled   = true
    }
  }

### Rule-05 : Allow API Enquiry path
  rule {
    name      = "allow-api-v1-files-enquiry"
    priority  = 5
    action {
      allow {}
    }
    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              uri_path {
              }
            }
            positional_constraint = "STARTS_WITH"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            search_string        = "/api/v1/files/Enquiry/"
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              uri_path {
              }
            }
            positional_constraint = "STARTS_WITH"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            search_string        = "/api/v1/upload/enquiries"
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule05"
      sampled_requests_enabled   = true
    }
  }

### Rule-11 : AWSManagedRulesKnownBadInputsRuleSet
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 11
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule11"
      sampled_requests_enabled   = true
    }
  }

### Rule-12 : AWSManagedRulesCommonRuleSet
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 12
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesCommonRuleSet"
        rule_action_override {
          # Added due to file uploads hitting this rule making body too big
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          # Added due to file uploads hitting this rule 
          name = "CrossSiteScripting_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule12"
      sampled_requests_enabled   = true
    }
  }

### Rule-13 : AWSManagedRulesAnonymousIpList
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 13
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesAnonymousIpList"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule13"
      sampled_requests_enabled   = true
    }
  }

### Rule-14 : AWSManagedRulesAmazonIpReputationList
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 14
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesAmazonIpReputationList"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule14"
      sampled_requests_enabled   = true
    }
  }

### Rule-15 : AWSManagedRulesLinuxRuleSet
  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 15
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesLinuxRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule15"
      sampled_requests_enabled   = true
    }
  }

### Rule-16 : AWSManagedRulesPHPRuleSet
  rule {
    name     = "AWSManagedRulesPHPRuleSet"
    priority = 16
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesPHPRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule16"
      sampled_requests_enabled   = true
    }
  }

### Rule-17 : AWSManagedRulesSQLiRuleSet
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 17
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesSQLiRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule17"
      sampled_requests_enabled   = true
    }
  }

### Rule-18 : AWSManagedRulesWindowsRuleSet
  rule {
    name     = "AWSManagedRulesWindowsRuleSet"
    priority = 18
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesWindowsRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule18"
      sampled_requests_enabled   = true
    }
  }

### Rule-19 : AWSManagedRulesUnixRuleSet
  rule {
    name     = "AWSManagedRulesUnixRuleSet"
    priority = 19
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesUnixRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule19"
      sampled_requests_enabled   = true
    }
  }

### Rule-31 : Allow IP from Office or Clinic Locations listed above
  rule {
    name     = "Office-Locations"
    priority = 31

    action {
      allow {}
    }
    statement {

      ip_set_reference_statement {
            arn = aws_wafv2_ip_set.waf_ip_set01[0].arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule31"
      sampled_requests_enabled   = true
    }
  }

### Rule-32 : Allow IP from DataAutomation team
  rule {
    name     = "External-Team"
    priority = 32

    action {
      allow {}
    }
    statement {

      ip_set_reference_statement {
            arn = aws_wafv2_ip_set.waf_ip_set05[0].arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule32"
      sampled_requests_enabled   = true
    }
  }

### Rule-37 : Allow IP from uptime-robot-IPV4
  rule {
    name     = "UptimeRobots-IPV4"
    priority = 37

    action {
      allow {}
    }
    statement {

      ip_set_reference_statement {
            arn = aws_wafv2_ip_set.waf_ip_set02[0].arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule37"
      sampled_requests_enabled   = true
    }
  }

### Rule-38 : Allow IP from uptime-robot-IPV6
  rule {
    name     = "UptimeRobots-IPV6"
    priority = 38

    action {
      allow {}
    }
    statement {

      ip_set_reference_statement {
            arn = aws_wafv2_ip_set.waf_ip_set03[0].arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule38"
      sampled_requests_enabled   = true
    }
  }

### Rule-41 : Allow IP from WebHook API
  rule {
    name     = "WebHook-API"
    priority = 41

    action {
      allow {}
    }
    statement {

      ip_set_reference_statement {
            arn = aws_wafv2_ip_set.waf_ip_set04[0].arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule41"
      sampled_requests_enabled   = true
    }
  }

#
# This is an example custom ruleset.  I do not think they should be used but if the
# WAF bans traffic you may need to insert some of these.  If possible use another metric
# like IP, or User-Agent to restrice it down so it auto allows them if they match that too.
#
#### Rule-42 : Custom - Allow traffic over api/v1/download
#  rule {
#    name      = "allow-api-download"
#    priority  = 42
#    action {
#      allow {}
#    }
#    statement {
#      byte_match_statement {
#        field_to_match {
#          uri_path {
#          }
#        }
#        positional_constraint = "EXACTLY"
#        text_transformation {
#          priority = 0
#          type     = "NONE"
#        }
#        search_string        = "/api/v1/download"
#      }
#    }
#    visibility_config {
#      cloudwatch_metrics_enabled = true
#      metric_name                = "aws-waf-firewall-rule42"
#      sampled_requests_enabled   = true
#    }
#  }

### Rule-43 : Allow certain API paths
  rule {
    name      = "allow-api-v1-paths"
    priority  = 43
    action {
      allow {}
    }
    statement {
      byte_match_statement {
        field_to_match {
          uri_path {
          }
        }
        positional_constraint = "STARTS_WITH"
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        search_string        = "/api/v1/"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule43"
      sampled_requests_enabled   = true
    }
  }

### Rule-45 : Allow certain API paths
  rule {
    name      = "allow-api-v2-paths"
    priority  = 45
    action {
      allow {}
    }
    statement {
      byte_match_statement {
        field_to_match {
          uri_path {
          }
        }
        positional_constraint = "STARTS_WITH"
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        search_string        = "/api/v2/"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule45"
      sampled_requests_enabled   = true
    }
  }


### Rule-61 : AWSManagedRulesBotControlRuleSet
  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 61
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesBotControlRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-waf-firewall-rule61"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "aws-waf-firewall"
    sampled_requests_enabled   = false
  }
  tags = {
    Name = "waf"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "waf"
  }
}


# Attach the WAF WebACL to an existing ALB
resource "aws_wafv2_web_acl_association" "waf_acl_alb" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.aws_waf_enabled) ? 1 : 0
  resource_arn	= aws_alb.product[0].arn
  web_acl_arn	= aws_wafv2_web_acl.waf_acl[0].arn
}


