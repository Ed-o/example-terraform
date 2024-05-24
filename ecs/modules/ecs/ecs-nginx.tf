# Nginx Web server

resource "aws_cloudwatch_log_group" "product_cloudwatch_nginx" {
  count = var.software.nginx.enabled ? 1 : 0
  name = "application-${var.software.nginx.name}${local.sharedname}"
  retention_in_days = var.network_settings.log_retention 
  kms_key_id = data.aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "nginx"
  }
}

resource "aws_ecs_task_definition" "nginx-task" {
  count 			= var.software.nginx.enabled ? 1 : 0
  family 			= "${var.software.nginx.name}${local.sharedname}"
  network_mode 			= "awsvpc"
  requires_compatibilities 	= ["FARGATE"]
  cpu 				= var.software.nginx.cpu
  memory 			= var.software.nginx.memory
  execution_role_arn		= data.aws_iam_role.ecs_task_role.arn
  task_role_arn			= data.aws_iam_role.ecs_task_role.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "nginx"
  }
  container_definitions = <<EOF
[
  {
    "name": "${var.software.nginx.name}",
    "image": "${var.software.nginx.repo}",
    "portMappings": [
      {
        "containerPort": ${var.software.nginx.port},
        "hostPort": ${var.software.nginx.port}
      }
    ],
    "essential": true,
    "readonlyRootFilesystem": false,
    "linuxParameters": {
      "initProcessEnabled": true
    },
    "environment": [
      { "name": "INTERNALDNS", "value": "${var.network_settings.dns_lookups}"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "application-${var.software.nginx.name}${local.sharedname}",
        "awslogs-region": "${var.network_settings.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
}


