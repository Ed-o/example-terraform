# Databases

locals {
  # The name of the logs gets an appended name if it is in a shared area
  dblogname = var.network_settings.shared_network ? "-${var.setup.name}" : ""
}


### ---> This part is for the RDS database (if set in the variables file)

resource "aws_db_subnet_group" "db_subnet" {
  count      = var.software.mysql.rds_servers_enabled || var.software.mysql.rds_serverless_enabled ? 1 : 0
  name       = "db_subnet_group${local.dblogname}"
  subnet_ids = flatten([local.subnet_private])
  tags = {
    Name = "DB subnet group"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
  }
}

# --> First lets make the RDS if it is a serverless cluster 

resource "aws_rds_cluster" "mysql_serverless_cluster" {
  count = var.software.mysql.rds_serverless_enabled ? 1 : 0
  cluster_identifier = "mysqlcluster-${var.setup.environment}${local.dblogname}"
  engine_mode = "serverless"
  engine = "aurora-mysql"
  # engine_version = var.software.mysql.rdsengine
  db_subnet_group_name = aws_db_subnet_group.db_subnet[0].name
  vpc_security_group_ids = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_db.id]
  database_name = "laravel"
  master_username = local.database_master_username
  master_password = local.database_master_password
  backup_retention_period = 7
  preferred_backup_window = "02:30-04:30"
  skip_final_snapshot = var.software.mysql.skip_final_snapshot
  scaling_configuration {
    auto_pause = true
    max_capacity = 4
    min_capacity = 2
    seconds_until_auto_pause = 300
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
    rdshardware = "serverless"
  }
}

# Create a CloudMap service instance for the RDS erverless ndpoint
resource "aws_service_discovery_instance" "rds_serverless_dns" {
  count = var.software.mysql.rds_serverless_enabled ? 1 : 0
  instance_id = "db"
  service_id = aws_service_discovery_service.mysql_app_name[0].id
  attributes = {
    "AWS_INSTANCE_CNAME" = aws_rds_cluster.mysql_serverless_cluster[0].endpoint
    # "AWS_INSTANCE_PORT" = "3306"
  }
}


# --> or we will make the RDS if it is an older style server cluster 

resource "aws_rds_cluster" "mysql_server_cluster" {
  count = var.software.mysql.rds_servers_enabled ? 1 : 0
  cluster_identifier = "mysqlcluster-${var.setup.environment}${local.dblogname}"
  engine = "aurora-mysql"
  engine_version = var.software.mysql.rdsengine
  db_subnet_group_name = aws_db_subnet_group.db_subnet[0].name
  vpc_security_group_ids = [data.aws_security_group.product_sg_db.id]
  master_username = local.database_master_username 
  master_password = local.database_master_password
  skip_final_snapshot = var.software.mysql.skip_final_snapshot
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
    rdshardware = "servers"
  }
}

resource "aws_rds_cluster_instance" "mysql_instance" {
  count = var.software.mysql.rds_servers_enabled ? var.software.mysql.rdscount : 0
  cluster_identifier = aws_rds_cluster.mysql_server_cluster[0].id
  instance_class = var.software.mysql.rdssize
  identifier = "${var.setup.name}-mysql-${format("%02d", count.index + 1)}"
  engine = "aurora-mysql"
  db_subnet_group_name = aws_db_subnet_group.db_subnet[0].name
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
  }
}

# Create a CloudMap service instance for the RDS endpoint
resource "aws_service_discovery_instance" "rds_server_dns" {
  count = var.software.mysql.rds_servers_enabled ? 1 : 0
  instance_id = "db"
  service_id = aws_service_discovery_service.mysql_app_name[0].id
  attributes = {
    "AWS_INSTANCE_CNAME" = aws_rds_cluster.mysql_server_cluster[0].endpoint
    # "AWS_INSTANCE_PORT" = "3306"
  }
}


### ----> This part is for the docker version of the database if you use that

# MYSQL DB inside ECS

resource "aws_cloudwatch_log_group" "product_cloudwatch_mysql" {
  count = var.software.mysql.ecs_enabled ? 1 : 0
  name = "application-${var.software.mysql.name}-logs${local.sharedname}"
  retention_in_days = var.network_settings.log_retention 
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
  }
}

resource "aws_ecs_task_definition" "mysql-task" {
  count 			= var.software.mysql.ecs_enabled ? 1 : 0
  family 			= "mysql-${var.setup.environment}"
  network_mode 			= "awsvpc"
  requires_compatibilities 	= ["FARGATE"]
  cpu 				= var.software.mysql.cpu
  memory 			= var.software.mysql.memory
  execution_role_arn		= data.aws_iam_role.ecs_task_role.arn
  volume {
    name = "vol-db"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.vol_database[0].id
      root_directory = "/"   # this is the folder inside the EFS to read
      transit_encryption = "DISABLED"
    }
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
  }
  container_definitions = <<EOF
[
  {
    "name": "${var.software.mysql.name}",
    "image": "${var.software.mysql.repo}",
    "portMappings": [
      {
        "containerPort": ${var.software.mysql.port},
        "hostPort": ${var.software.mysql.port}
      }
    ],
    "mount_points": [
      {
        "container_path": "/usr/share/mysql",
        "source_volume": "vol-db",
        "read_only": false
      }
    ],
    "essential": true,
    "environment": [
      {"name": "MYSQL_ROOT_USER", "value": "${local.database_master_username}"},
      {"name": "MYSQL_ROOT_PASSWORD", "value": "${local.database_master_password}"},
      {"name": "MYSQL_DATABASE", "value": "${local.database_app_database}"},
      {"name": "MYSQL_USER", "value": "${local.database_app_username}"},
      {"name": "MYSQL_PASSWORD", "value": "${local.database_app_password}"}

    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "application-${var.software.mysql.name}-logs${local.sharedname}",
        "awslogs-region": "${var.network_settings.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "mysql-service" {
  count 	  = var.software.mysql.ecs_enabled ? 1 : 0
  name            = "${var.software.mysql.name}"
  cluster         = aws_ecs_cluster.product.id
  task_definition = aws_ecs_task_definition.mysql-task[0].arn
  desired_count   = "${var.software.mysql.desired_count}"
  launch_type	  = "FARGATE"

  network_configuration {
    subnets = local.subnet_private 
    security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_db.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mysql_app_ip[0].arn
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
  }
}


### ---> And this part for a local file
resource "local_file" "example" {
  count = var.software.mysql.local_enabled ? 1 : 0
  filename = "/etc/mysql/my.cnf"
  content = "# local MySQL configuration"
  # ... other local file properties
}


