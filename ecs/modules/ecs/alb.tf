# Load Balancer

resource "aws_alb" "product" {
  count 	  = var.loadbalancer.loadbalancer_enabled ? 1 : 0
  name            = "product"
  internal        = false
  security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_web.id]
  subnets         = var.loadbalancer.loadbalancer_public ? flatten([for subnet in aws_subnet.subnet_public : subnet.id]) : flatten([for subnet in aws_subnet.subnet_private : subnet.id])
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb"
  }
}

resource "aws_alb_target_group" "product" {
  count = (var.loadbalancer.loadbalancer_enabled && ((var.loadbalancer.protocol_in == "HTTP") || (var.loadbalancer.protocol_in == "HTTPS" ))) ? 1 : 0
  name		= "product-${var.setup.name}"
  port		= 80
  protocol 	= "HTTP" 
  vpc_id   	= "${data.aws_vpc.selected.id}"
  target_type 	= "ip"
  health_check {
    path = "/"
    interval 	= 30
    timeout 	= 10
    healthy_threshold 	= 2
    unhealthy_threshold = 2
    matcher = "200,302"
  }  
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb"
  }
}

#resource "aws_alb_listener" "listener_http" {
#  # count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.protocol_in == "HTTP") ? 1 : 0
#  count = (var.loadbalancer.loadbalancer_enabled) ? 1 : 0
#  load_balancer_arn = aws_alb.product[0].arn
#  port              = 80
#  protocol          = "HTTP"
#
#  default_action {
#    target_group_arn = aws_alb_target_group.product[0].arn
#    type             = "forward"
#  }
#  tags = {
#    Name = "product-${var.setup.name}"
#    environment = var.setup.environment
#    creator = var.setup.creator
#    asset = "alb"
#  }
#}

resource "aws_alb_listener" "listener_https" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.protocol_in == "HTTPS") ? 1 : 0
  load_balancer_arn = aws_alb.product[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert[0].arn

  default_action {
    target_group_arn = aws_alb_target_group.product[0].arn
    type             = "forward"
  }
  tags = {
    Name = "product-${var.setup.name}"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb"
  }
}

# Work out the name for the ELB
locals {
  lb_name = var.loadbalancer.loadbalancer_shared == "" ? var.setup.base_url : "product-elb.${var.setup.base_url}"
  cert_name = var.loadbalancer.loadbalancer_shared == "" ? var.setup.base_url : "*.${var.setup.base_url}"
  # We extra the domain cert validation methods into a local variable so we can use it in the next function to make DNS entries (if needed) this was done as you cannot mix a count statement with a for_each statement
  certs = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.protocol_in == "HTTPS" && var.setup.alt_url == "" ) ? aws_acm_certificate.cert[0].domain_validation_options : []

}

resource "aws_acm_certificate" "cert" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.protocol_in == "HTTPS" && var.setup.alt_url == "" ) ? 1 : 0
  domain_name               = local.cert_name
  validation_method         = "DNS"
  tags = {
    Name = "product-${var.setup.name}"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb-tlscert"
  }
}

resource "aws_route53_record" "dns_for_cert" {
  for_each = { 
    for dvo in local.certs : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = "${var.network_settings.dns_zone}"
    }
  } 

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count = (var.loadbalancer.loadbalancer_enabled && var.loadbalancer.protocol_in == "HTTPS") ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dns_for_cert : record.fqdn]
}


# Add DNS for LB access :
resource "aws_route53_record" "dns_nginx_with_lb" {
  count   = (var.network_settings.dns_enabled && var.software.nginx.enabled && var.loadbalancer.loadbalancer_enabled) ? 1 : 0
  zone_id = var.network_settings.dns_zone
  name    = local.lb_name
  type    = "CNAME"
  ttl     = "30"
  records = [ aws_alb.product[0].dns_name ]
}
