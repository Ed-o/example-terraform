resource "aws_alb" "alb" {
  name            = "${var.setup.name}"
  internal        = false
  security_groups = [
    "${aws_security_group.ecs_alb.id}"
  ]
  subnets         = flatten([for subnet in aws_subnet.zabbix_public_subnets : subnet.id])
}

resource "aws_alb_target_group" "zabbix_target_group" {
  name     = "tg-${var.setup.name}"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.selected.id}"
  target_type   = "ip"
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/"
    interval            = 10
    matcher             = "200,301,302"
    port                = "80"
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "alb"
  }
}

resource "aws_alb_listener" "alb_listener_https" {
  count             = "${var.loadbalancer.aws_certificate_arn == false ? 0 : 1}"
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${var.loadbalancer.aws_certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.zabbix_target_group.arn}"
    type = "forward"
  }
}

resource "aws_alb_listener" "alb_listener_http" {
  count             = "${var.loadbalancer.aws_certificate_arn == false ? 1 : 0}"
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.zabbix_target_group.arn}"
    type = "forward"
  }
}
