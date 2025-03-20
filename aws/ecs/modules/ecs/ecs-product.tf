# Product Server

resource "aws_cloudwatch_log_group" "product_cloudwatch_product" {
  count = var.software.product.enabled ? 1 : 0
  name = "application-${var.software.product.name}${local.sharedname}"
  retention_in_days = var.network_settings.log_retention 
  kms_key_id = data.aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-product"
  }
}

locals {
  efs_images_mountpoint_string = <<EOF1
    "mountPoints": [
      {
        "containerPath": "/data/product",
        "sourceVolume": "vol-img-${var.setup.name}",
        "readOnly": false
      }
    ],
    EOF1
  volume_string = <<EOF2
  volume {
    name                = "vol-img-${var.setup.name}"
    efs_volume_configuration {
      file_system_id    = aws_efs_file_system.vol_images[0].id
      root_directory    = "/"
    }
  }
  EOF2
  efs_images_mountpoints = (var.storage.efs_images_enable) ? local.efs_images_mountpoint_string : ""
}

locals {
  container_definitions = <<EOF3
[
  {
    "name": "${var.software.product.name}",
    "image": "${var.software.product.repo}",
    "portMappings": [
      {
        "containerPort": ${var.software.product.port},
        "hostPort": ${var.software.product.port}
      }
    ],
    ${local.efs_images_mountpoints}
    "essential": true,
    "readonlyRootFilesystem": false,
    "linuxParameters": {
      "initProcessEnabled": true
    },
    "environment": [ 
      { "name": "APP_ID", "value": "${var.software.product.environment.APP_ID}"},
      { "name": "APP_NAME", "value": "${var.software.product.environment.APP_NAME}"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "application-${var.software.product.name}${local.sharedname}",
        "awslogs-region": "${var.network_settings.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF3
}

resource "aws_ecs_task_definition" "product-task" {
  count				= (var.software.product.enabled) ? 1 : 0
  family 			= "product${local.sharedname}"
  network_mode 			= "awsvpc"
  requires_compatibilities 	= ["FARGATE"]
  cpu 				= var.software.product.cpu
  memory 			= var.software.product.memory
  execution_role_arn		= data.aws_iam_role.ecs_task_role.arn
  task_role_arn			= data.aws_iam_role.ecs_task_role.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-product"
  }
  dynamic "volume" {
    for_each = (var.storage.efs_images_enable) ? [1] : []
    content {
      name      		= "vol-img-${var.setup.name}"
      efs_volume_configuration {
        file_system_id 	= aws_efs_file_system.vol_images[0].id
        root_directory 	= "/"
      }
    }
  }
  container_definitions = "${local.container_definitions}"
}

resource "aws_ecs_service" "product-service" {
  count		  = var.software.product.enabled ? 1 : 0
  name            = "${var.software.product.name}"
  cluster         = aws_ecs_cluster.product.id
  task_definition = aws_ecs_task_definition.product-task[0].arn
  desired_count   = "${var.software.product.desired_count}"
  launch_type	  = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = local.subnet_private # selected
    security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_app.id]
  } 

  service_registries {
    registry_arn = aws_service_discovery_service.product_app.arn
  }

  dynamic "load_balancer" {
    for_each = (!var.software.nginx.enabled) ? [1] : []
    content {
      target_group_arn = aws_alb_target_group.product_tg_product[0].arn
      container_name   = "${var.software.product.name}"
      container_port   = "${var.software.product.port}"
    }
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "app-product"
  }
}

