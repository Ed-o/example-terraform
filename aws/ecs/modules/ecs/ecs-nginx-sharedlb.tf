# Nginx Web server - with ia shared LB

resource "aws_ecs_service" "nginx-service-with-sharedlb" {
  count           = (var.software.nginx.enabled && !(var.loadbalancer.loadbalancer_enabled) && var.loadbalancer.loadbalancer_shared != "") ? 1 : 0
  name            = "${var.software.nginx.name}"
  cluster         = aws_ecs_cluster.product.id
  task_definition = aws_ecs_task_definition.nginx-task[0].arn
  desired_count   = "${var.software.nginx.desired_count}"
  launch_type	  = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = local.subnet_private
    security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.ecs-internal.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.product_tg_nginx[0].arn
    container_name   = "${var.software.nginx.name}" 
    container_port   = "${var.software.nginx.port}"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "nginx"
  }
}




