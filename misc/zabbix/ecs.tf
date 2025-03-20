# ECS services and cluster

# First we make the main cluster.  This can be for EC2 or ECS hosting

resource "aws_ecs_cluster" "cluster_zabbix" {
  name = "${var.setup.name}"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.zabbix_cloudwatch.name
      }
    }
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "ecs-cluster"
  }
  depends_on = [aws_cloudwatch_log_stream.zabbix_ecs_log_stream]
}

# A template file to be used for settings for the machines and software
data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data")}"
  vars = {
    cluster_name = "${var.setup.name}"
  }
}

### Create the setup for EC2 servers as hosts --->

resource "aws_launch_configuration" "launch_configuration_zabbix_ecs_key" {
  count                = var.software.zabbix.launch_type == "EC2" ? 1 : 0
  name_prefix          = "ecs-${var.setup.name}-"
  instance_type        = "${var.software.zabbix.aws_instance_type}"
  image_id             = "${var.software.zabbix.aws_ami}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.id}"
  security_groups      = [
    "${aws_security_group.ecs_instance.id}"
  ]
  user_data            = "${data.template_file.user_data.rendered}"

  key_name             = "${var.software.zabbix.public_key}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group_zabbix_ecs_key" {
  count                = var.software.zabbix.launch_type == "EC2" ? 1 : 0
  name                 = "ecs-cluster-${var.setup.name}"
  vpc_zone_identifier  = flatten([for subnet in aws_subnet.zabbix_private_subnets : subnet.id])
  min_size             = "${var.software.zabbix.min_size}"
  max_size             = "${var.software.zabbix.max_size}"
  desired_capacity     = "${var.software.zabbix.desired_size}"
  launch_configuration = "${aws_launch_configuration.launch_configuration_zabbix_ecs_key[0].name}"
  health_check_type    = "EC2"
  target_group_arns    = [
    "${aws_alb_target_group.zabbix_target_group.arn}",
  ]
  tag {
    key                 = "Name"
    value               = "ecs-${var.setup.name}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ecs_container_definition" "container_definition" {
  task_definition = "${aws_ecs_task_definition.task.id}"
  container_name = "${var.setup.name}"
}

resource "aws_ecs_service" "service" {
  name = "${var.setup.name}"
  cluster = "${aws_ecs_cluster.cluster_zabbix.id}"
  task_definition = "${aws_ecs_task_definition.task.arn}"
  desired_count = 1
  launch_type = "${var.software.zabbix.launch_type}"
  enable_execute_command = true

  network_configuration {
    subnets = [for subnet in aws_subnet.zabbix_private_subnets : subnet.id]
    security_groups = [aws_security_group.ecs_instance.id]
  }

#  volume {
#    name      = "app_store_volume"
#    host_path = "/root/.config/app"
#  }

  load_balancer {
    target_group_arn = aws_alb_target_group.zabbix_target_group.arn
    container_name   = "${var.setup.name}"
    container_port   = "${var.software.zabbix.webport}"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "zabbix"
  }
}

resource "aws_ecs_task_definition" "task" {
  family = "${var.setup.name}"
  network_mode                  = "awsvpc"
  requires_compatibilities      = ["${var.software.zabbix.launch_type}"]
  cpu                           = var.software.zabbix.cpu
  memory                        = var.software.zabbix.memory
  execution_role_arn            = aws_iam_role.ecs_task_role.arn
  task_role_arn                 = aws_iam_role.ecs_task_role.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "zabbix"
  }
  container_definitions = <<DEFINITION
[
    {
		"name": "${var.setup.name}",
		"image": "${var.software.zabbix.repo}",
		"essential": true,
		"portMappings": [
			{
				"containerPort": ${var.software.zabbix.webport},
				"hostPort": ${var.software.zabbix.webport}
			},
			{
				"containerPort": ${var.software.zabbix.intport},
				"hostPort": ${var.software.zabbix.intport}
			}
		],
		"environment" : [
			{
				"name" : "ZS_DBHost",
				"value" : "${local.db_address}"
			},
			{
				"name" : "ZS_DBUser",
				"value" : "${local.ec2_creds.username}"
			},
			{
				"name" : "ZS_DBPassword",
				"value" : "${local.ec2_creds.password}"
			}
		]
	}
]
DEFINITION
}
