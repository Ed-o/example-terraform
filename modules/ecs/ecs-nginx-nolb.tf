# Nginx Web server - with no LB

resource "aws_ecs_service" "nginx-service-without-lb" {
  count           = (var.software.nginx.enabled && !(var.loadbalancer.loadbalancer_enabled) && var.loadbalancer.loadbalancer_shared == "") ? 1 : 0
  name            = "${var.software.nginx.name}"
  cluster         = aws_ecs_cluster.product.id
  task_definition = aws_ecs_task_definition.nginx-task[0].arn
  desired_count   = "${var.software.nginx.desired_count}"
  launch_type     = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = local.subnet_public
    security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_web.id]
    assign_public_ip = var.software.nginx.public
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.nginx_app[0].arn
  }

  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "nginx"
    note = "No ELB"
  }
}

#resource "aws_route53_record" "dns_nginx" {
#  count   = (var.network_settings.dns_enabled && var.software.nginx.enabled && !(var.loadbalancer.loadbalancer_enabled)) ? 1 : 0
#  zone_id = var.network_settings.dns_zone
#  name    = "${var.setup.base_url}"
#  type    = "CNAME"
#  ttl     = "30"
#  records = [ "nginx_app.discover.${var.setup.base_url}" ]
#}



