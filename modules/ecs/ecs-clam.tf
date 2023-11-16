# ClamAV Server

resource "aws_cloudwatch_log_group" "product_cloudwatch_clamav" {
  count = var.software.clamav.enabled ? 1 : 0
  name = "application-${var.software.clamav.name}${local.sharedname}"
  retention_in_days = var.network_settings.log_retention 
  kms_key_id = data.aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-clamav"
  }
}

resource "aws_ecs_task_definition" "clamav-task" {
  count				= var.software.clamav.enabled ? 1 : 0
  family 			= "clamav${local.sharedname}"
  network_mode 			= "awsvpc"
  requires_compatibilities 	= ["FARGATE"]
  cpu 				= var.software.clamav.cpu
  memory 			= var.software.clamav.memory
  execution_role_arn		= data.aws_iam_role.ecs_task_role.arn
  task_role_arn			= data.aws_iam_role.ecs_task_role.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-clamav"
  }
  container_definitions = <<EOF
[
  {
    "name": "${var.software.clamav.name}",
    "image": "${var.software.clamav.repo}",
    "portMappings": [
      {
        "containerPort": ${var.software.clamav.port},
        "hostPort": ${var.software.clamav.port}
      }
    ],
    "essential": true,
    "readonlyRootFilesystem": false,
    "linuxParameters": {
      "initProcessEnabled": true
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "application-${var.software.clamav.name}${local.sharedname}",
        "awslogs-region": "${var.network_settings.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "clamav-service" {
  count		  = var.software.clamav.enabled ? 1 : 0
  name            = "${var.software.clamav.name}"
  cluster         = aws_ecs_cluster.product.id
  task_definition = aws_ecs_task_definition.clamav-task[0].arn
  desired_count   = "${var.software.clamav.desired_count}"
  launch_type	  = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = local.subnet_private
    security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_clamav.id]
  } 

  service_registries {
    registry_arn = aws_service_discovery_service.clamav_app.arn
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-clamav"
  }
}

