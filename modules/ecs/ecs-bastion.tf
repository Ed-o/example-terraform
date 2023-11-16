# This is a one-time run bastion (ie it is not running all the time)
# It will also be used to setup the database etc on start up

resource "aws_cloudwatch_log_group" "product_cloudwatch_bastion" {
  count = var.software.bastion.enabled ? 1 : 0
  name = "application-${var.software.bastion.name}${local.sharedname}"
  retention_in_days = var.network_settings.log_retention
  kms_key_id = data.aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-bastion"
  }
}

locals {
  bastion_container_definitions = <<EOF
[
  {
    "name": "${var.software.bastion.name}",
    "image": "${var.software.bastion.repo}",
    "portMappings": [
      {
        "containerPort": ${var.software.bastion.port},
        "hostPort": ${var.software.bastion.port}
      }
    ],
    "essential": true,
    "readonlyRootFilesystem": false,
    "linuxParameters": {
      "initProcessEnabled": true
    },
    "environment": [
      { "name": "APP_ID", "value": "Bastion"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "application-${var.software.bastion.name}${local.sharedname}",
        "awslogs-region": "${var.network_settings.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
}

resource "aws_ecs_task_definition" "bastion_task" {
  count                    = var.software.bastion.enabled ? 1 : 0
  family                   = "bastion${local.sharedname}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.software.bastion.cpu
  memory                   = var.software.bastion.memory
  execution_role_arn       = data.aws_iam_role.ecs_task_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_role.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-bastion"
  }
  dynamic "volume" {
    for_each = (var.storage.efs_images_enable) ? [1] : []
    content {
      name                      = "vol-img-${var.setup.name}"
      efs_volume_configuration {
        file_system_id  = aws_efs_file_system.vol_images[0].id
        root_directory  = "/"
      }
    }
  }
  container_definitions = "${local.bastion_container_definitions}"
}

# Define the ECS service 
resource "aws_ecs_service" "bastion_service" {
  count           = var.software.bastion.enabled ? 1 : 0
  name            = "${var.software.bastion.name}"
  cluster         = aws_ecs_cluster.product.id
  task_definition = aws_ecs_task_definition.bastion_task[0].arn
  desired_count   = 0
  launch_type     = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = local.subnet_private
    security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_app.id]
  }
  depends_on = [aws_ecs_cluster.product]
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-bastion"
  }
}


