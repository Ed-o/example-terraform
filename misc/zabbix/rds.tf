# RDS Database for Zabbix :

### ---> This part is for the RDS database (if set in the variables file)

resource "aws_db_subnet_group" "db_subnet" {
  count      = var.software.database.rds_servers_enabled || var.software.database.rds_serverless_enabled ? 1 : 0
  name       = "rds_${var.setup.name}"
  subnet_ids = flatten([for subnet in aws_subnet.zabbix_private_subnets : subnet.id])
  tags = {
    Name = "DB subnet group"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
  }
}

resource "aws_db_parameter_group" "zabbix-rds-setting" {
  name = "zabbix-rds-setting"
  family = "mysql5.7"
  parameter {
    name = "character_set_client"
    value = "utf8"
  }
  parameter {
    name = "character_set_connection"
    value = "utf8"
  }
  parameter {
    name = "character_set_database"
    value = "utf8"
  }
  parameter {
    name = "character_set_filesystem"
    value = "utf8"
  }
  parameter {
    name = "character_set_results"
    value = "utf8"
  }
  parameter {
    name = "character_set_server"
    value = "utf8"
  }
  parameter {
    name = "collation_connection"
    value = "utf8_bin"
  }
  parameter {
    name = "collation_server"
    value = "utf8_bin"
  }
}

# --> First lets make the RDS if it is a serverless cluster

resource "aws_rds_cluster" "db-rds-serverless-cluster" {
  count = var.software.database.rds_serverless_enabled ? 1 : 0
  engine_mode = "serverless"
  engine = "aurora-mysql"
  # engine_version = var.software.database.serverless_engine
  cluster_identifier = "zabbix-mysqlcluster"
  db_subnet_group_name = aws_db_subnet_group.db_subnet[0].name
  vpc_security_group_ids = [aws_security_group.rds_instance.id]
  database_name = "zabbix"
  master_username = "${local.ec2_creds.username}"
  master_password = "${local.ec2_creds.password}"
  backup_retention_period = 7
  preferred_backup_window = "02:30-04:30"
  scaling_configuration {
    auto_pause = true
    max_capacity = 4
    min_capacity = 1
    seconds_until_auto_pause = 300
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
    rdshardware = "serverless"
  }
}

# --> or we will make the RDS if it is an older style server cluster

resource "aws_db_instance" "db-rds-server" {
  count 		  = var.software.database.rds_servers_enabled ? 1 : 0
  allocated_storage       = 10
  storage_type            = "gp2"
  engine                  = "${var.software.database.engine}"
  engine_version          = "${var.software.database.engine_version}"
  instance_class          = "${var.software.database.aws_db_instance_type}"
  identifier              = "${var.setup.name}"
  db_name                 = "${var.setup.name}"
  username                = "${local.ec2_creds.username}"
  password                = "${local.ec2_creds.password}"
  db_subnet_group_name    = "${aws_db_subnet_group.db_subnet[0].name}"
  vpc_security_group_ids  = ["${aws_security_group.rds_instance.id}"]
  parameter_group_name    = "${aws_db_parameter_group.zabbix-rds-setting.name}"
  backup_retention_period = "${var.software.database.aws_db_backup_days}"
  backup_window           = "02:30-04:30"
  maintenance_window      = "mon:05:00-mon:07:00"
  multi_az                = "${var.network_settings.high_availability}"
  skip_final_snapshot     = true
  apply_immediately       = true
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
    rdshardware = "server"
  }
}

# And here we store the database address 
locals {
  db_address = var.software.database.rds_servers_enabled ? aws_db_instance.db-rds-server[0].address : aws_rds_cluster.db-rds-serverless-cluster[0].endpoint
}



