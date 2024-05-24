# Redis Cache

### ---> This part is used if it is inside ElastiCache in AWS

resource "aws_elasticache_subnet_group" "redis_subnets" {
  count      = var.software.redis.aws_redis_enabled ? 1 : 0
  name       = "redis-subnets"
  subnet_ids = flatten([local.subnet_private])
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "redis"
  }
}

resource "aws_elasticache_cluster" "redis" {
  count 	       = var.software.redis.aws_redis_enabled ? 1 : 0
  cluster_id           = "redis"
  engine               = "redis"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets[0].name  
  security_group_ids   = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_redis.id]
  node_type            = var.software.redis.redis_size
  num_cache_nodes      = 1
  parameter_group_name = var.software.redis.redis_param_group
  engine_version       = var.software.redis.redis_engine_version
  port                 = var.software.redis.port
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "redis"
  }
}


### ---> And this part if it is in ECS

resource "aws_cloudwatch_log_group" "product_cloudwatch_redis" {
  count = var.software.redis.ecs_redis_enabled ? 1 : 0
  name = "application-${var.software.redis.name}-${local.sharedname}"
  retention_in_days = var.network_settings.log_retention
  kms_key_id = data.aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "redis"
  }
}

resource "aws_ecs_task_definition" "redis-task" {
  count                         = var.software.redis.ecs_redis_enabled ? 1 : 0
  family                        = "redis-${var.setup.environment}"
  network_mode                  = "awsvpc"
  requires_compatibilities      = ["FARGATE"]
  cpu                           = var.software.redis.cpu
  memory                        = var.software.redis.memory
  execution_role_arn            = data.aws_iam_role.ecs_task_role.arn
  task_role_arn			= data.aws_iam_role.ecs_task_role.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "redis"
  }
  container_definitions = <<EOF
[
  {
    "name": "${var.software.redis.name}",
    "image": "${var.software.redis.repo}",
    "portMappings": [
      {
        "containerPort": ${var.software.redis.port},
        "hostPort": ${var.software.redis.port}
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
        "awslogs-group": "application-${var.software.redis.name}-${local.sharedname}",
        "awslogs-region": "${var.network_settings.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "redis-service" {
  count           = var.software.redis.ecs_redis_enabled ? 1 : 0
  name            = "${var.software.redis.name}"
  cluster         = aws_ecs_cluster.product.id
  task_definition = aws_ecs_task_definition.redis-task[0].arn
  desired_count   = "${var.software.redis.desired_count}"
  launch_type     = "FARGATE"
  enable_execute_command = true

  network_configuration {
    # subnets = [for subnet in aws_subnet.subnet_private : subnet.id]
    subnets = local.subnet_private
    security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_redis.id]
  }
  service_registries {
    registry_arn = aws_service_discovery_service.redis_app_ip[0].arn
  }
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "redis"
  }
}

# Create Cloud Map instance
resource "aws_service_discovery_instance" "redis_dns_app_instance" {
  count       = var.software.redis.aws_redis_enabled ? 1 : 0
  instance_id = "redis"
  service_id  = aws_service_discovery_service.redis_app_name[0].id
  attributes  = {
    "AWS_INSTANCE_CNAME" = aws_elasticache_cluster.redis[0].cache_nodes[0].address
  }
}


