# Security Groups

resource "aws_security_group" "ecs_alb" {
  name_prefix = "ecs-alb-zabbix-"
  #description = "Allow all inbound http(s) traffic"
  description = "Allow all inbound https traffic"
  vpc_id = "${data.aws_vpc.selected.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "1.1.1.1/32"]
    description = "Office"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "1.1.1.1/32"]
    description = "Office"
  }

  ingress {
    from_port = 10051
    to_port = 10051
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "Incoming zabbix clients"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_instance" {
  name_prefix = "zabbix-ecs-"
  description = "Allow http cluster traffic on ports 80"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.ecs_alb.id}"]
  }

  ingress {
    from_port = 10051
    to_port = 10051
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_instance" {
  name_prefix = "zabbix-rds-"
  description = "Allow http cluster traffic on ports 3306"
  vpc_id = "${data.aws_vpc.selected.id}"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.ecs_instance.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}
