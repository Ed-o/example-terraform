
resource "aws_alb_target_group" "product_tg_nginx" {
  count = (var.loadbalancer.loadbalancer_shared != "" && ((var.loadbalancer.protocol_in == "HTTP") || (var.loadbalancer.protocol_in == "HTTPS" )) && var.software.nginx.enabled) ? 1 : 0
  name		= "product-nginx-${var.setup.name}"
  port		= 80
  protocol 	= "HTTP"
  vpc_id   	= "${data.aws_vpc.selected.id}"
  target_type 	= "ip"
  deregistration_delay = "30"
  health_check {
    path 		= "/health"
    interval 		= 30
    timeout 		= 29
    healthy_threshold 	= 2
    unhealthy_threshold = 2
    matcher             = "200"
    port                = "traffic-port"
  }  
  stickiness {
    cookie_duration = 43200    # 12 Hours as seconds
    type = "lb_cookie"
    enabled = true
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb"
  }
}

resource "aws_alb_target_group" "product_tg_product" {
  count = (var.loadbalancer.loadbalancer_shared != "" && ((var.loadbalancer.protocol_in == "HTTP") || (var.loadbalancer.protocol_in == "HTTPS" )) && !var.software.nginx.enabled) ? 1 : 0
  name          = "product-app-${var.setup.name}"
  port          = 8000
  protocol      = "HTTP"
  vpc_id        = "${data.aws_vpc.selected.id}"
  target_type   = "ip"
  deregistration_delay = "30"
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 29
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
    port                = "traffic-port"
  }
  stickiness {
    cookie_duration = 43200    # 12 Hours as seconds
    type = "lb_cookie"
    enabled = true
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb"
  }
}

resource "aws_alb_target_group" "product_tg_productpwa" {
  count = (var.loadbalancer.loadbalancer_shared != "" && ((var.loadbalancer.protocol_in == "HTTP") || (var.loadbalancer.protocol_in == "HTTPS" )) && !var.software.nginx.enabled) ? 1 : 0
  name          = "product-pwa-${var.setup.name}"
  port          = 80
  protocol      = "HTTP"
  vpc_id        = "${data.aws_vpc.selected.id}"
  target_type   = "ip"
  deregistration_delay = "30"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 29
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
    port                = "traffic-port"
  }
  stickiness {
    cookie_duration = 43200    # 12 Hours as seconds
    type = "lb_cookie"
    enabled = true
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb"
  }
}

## Define the listener rules

locals {
  rnd = parseint(replace(uuid(), "-", ""), 16) % 10000 # generate a unique priority value using the uuid function
}

resource "aws_lb_listener_rule" "https_url_nginx_rule" {
  count = (var.loadbalancer.loadbalancer_shared != "" && ((var.loadbalancer.protocol_in == "HTTP") || (var.loadbalancer.protocol_in == "HTTPS" )) && var.software.nginx.enabled) ? 1 : 0
  listener_arn = var.loadbalancer.loadbalancer_shared_https
  priority     = "${local.rnd}"
  condition {
    host_header {
      values = [var.setup.base_url]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.product_tg_nginx[0].arn
  }
  lifecycle {
    ignore_changes = [priority]
  }
}

resource "aws_lb_listener_rule" "https_url_app_rule" {
  count = (var.loadbalancer.loadbalancer_shared != "" && ((var.loadbalancer.protocol_in == "HTTP") || (var.loadbalancer.protocol_in == "HTTPS" )) && !var.software.nginx.enabled) ? 1 : 0
  listener_arn = var.loadbalancer.loadbalancer_shared_https
  priority     = "${local.rnd +2}"
  condition {
    host_header {
      values = [var.setup.base_url]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.product_tg_product[0].arn
  }
  lifecycle {
    ignore_changes = [priority]
  }
}


# Add DNS for LB access :
resource "aws_route53_record" "dns_for_lb" {
  count   = (var.loadbalancer.loadbalancer_shared != "") ? 1 : 0
  zone_id = var.network_settings.dns_zone
  name    = var.setup.base_url
  type    = "CNAME"
  ttl     = "30"
  records = [ var.loadbalancer.loadbalancer_url ]
}
