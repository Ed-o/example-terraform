# The Security groups we will use

### First lets define the Public / Non-Public IPs 


locals {
    private_incoming_cidrv4 = [ 
    {
      cidr_block   = "1.1.1.1/32"
      description  = "Office"
    }
    ]
    private_incoming_cidrv4_webhook_ips = [ 
    {
      cidr_block   = "1.1.1.1/32"
    }
    ]
    # private_incoming_cidrv6 = [ "::/0" ]
}  

# Create a map of ingress rules
locals {
  ingress_rules_map = {
    # Rules with individual descriptions
    for idx, rule in local.private_incoming_cidrv4 : idx => {
      from_port   = 443 
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [rule.cidr_block]
      description = rule.description
    }
  }
  ingress_rules_map_webhook_ips = {
    # Rules with same description as each other
    for idx, rule in local.private_incoming_cidrv4_webhook_ips : idx => {
      from_port   = 443 
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [rule.cidr_block]
      description = "webhook ips"
    }
  }
}

### Now we setup the incoming web SG.  There is a public one and a private (NAT/Office one)

resource "aws_security_group" "product_sg_web_public" {
  count = (var.network_settings.shared_network == "false" && var.loadbalancer.visibility == "global") ? 1 : 0  # Only make these if not shared network
  name   		= "web-ports"
  description		= "Security group to allow inbound web traffic"
  vpc_id 		= "${data.aws_vpc.selected.id}"
  tags = {
    Name		= "web-ports"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Http from Internet"
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Https from Internet"
  }
}

resource "aws_security_group" "product_sg_web_private" {
  count = (var.network_settings.shared_network == "false"  && var.loadbalancer.visibility != "global") ? 1 : 0  # Only make these if not shared network
  name                  = "web-ports"
  description           = "Security group to allow inbound web traffic"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "web-ports"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  dynamic "ingress" {
    for_each = local.ingress_rules_map
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "ingress" {
    for_each = local.ingress_rules_map_stripe_webhook_ips
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
}

### Then we define the rest of the security groups that will be used internally

resource "aws_security_group" "ecs-internal" {
  count = var.network_settings.shared_network == "false" ? 1 : 0  # Only make these if not shared network
  name                  = "ecs-internal"
  description           = "Security group for ECS pods to talk to each other"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "ecs-internal"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    security_groups   = [aws_security_group.ecs-pods[0].id]
    description       = "Internal web traffic"
  }
}

resource "aws_security_group" "ecs-pods" {
  count = var.network_settings.shared_network == "false" ? 1 : 0  # Only make these if not shared network
  name                  = "ecs-pods"
  description           = "Security group for all ECS pods to live in"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "ecs-pods"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    self              = true
    description       = "Loopback"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All Outgoing"
  }
}

resource "aws_security_group" "product_sg_app" {
  count = var.network_settings.shared_network == "false" ? 1 : 0
  name                  = "product-app-ports"
  description           = "Security group to allow app traffic"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "product-app-ports"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups  = [aws_security_group.ecs-pods[0].id]
    description      = "App http web traffic"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    security_groups  = [aws_security_group.ecs-pods[0].id]
    description      = "App https web traffic"
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    security_groups  = [aws_security_group.ecs-pods[0].id]
    description      = "App internal traffic"
  }
}

resource "aws_security_group" "product_sg_report" {
  count = var.network_settings.shared_network == "false" ? 1 : 0
  name                  = "product-report-ports"
  description           = "Security group to allow report traffic"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "product-report-ports"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Report traffic"
  }
}

resource "aws_security_group" "product_sg_redis" {
  count = var.network_settings.shared_network == "false" ? 1 : 0
  name                  = "product-redis-ports"
  description           = "Security group to allow redis traffic"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "product-redis-ports"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups  = [aws_security_group.ecs-pods[0].id]
    description      = "redis traffic"
  }
}

resource "aws_security_group" "product_sg_clamav" {
  count = var.network_settings.shared_network == "false" ? 1 : 0
  name                  = "clamav-ports"
  description           = "Security group to allow clamav traffic"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "clamav-ports"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port   = 3310
    to_port     = 3310
    protocol    = "tcp"
    security_groups  = [aws_security_group.ecs-pods[0].id]
    description      = "clamav traffic"
  }
}

resource "aws_security_group" "product_sg_db" {
  count = var.network_settings.shared_network == "false" ? 1 : 0
  name                  = "db-ports"
  description           = "Security group to allow inbound db traffic"
  vpc_id                = "${data.aws_vpc.selected.id}"
  tags = {
    Name                = "db-ports"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "security-groups"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups  = [aws_security_group.ecs-pods[0].id]
    description      = "DB MySQL traffic"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.network_settings.vpc_cidr}"]
    description      = "DB MySQL traffic"
  }
}

data "aws_security_group" "ecs-pods" {
    name = var.network_settings.shared_network ? "ecs-pods" : aws_security_group.ecs-pods[0].name
}

data "aws_security_group" "product_sg_web" {
    # The main incoming web security group is set based on
    # is it a shared network ? Yes then use the already defined group 'web-ports'
    # no ? then check if it should be public visibility - 
    # if yes then define a public one, if no define a private one
    name = var.network_settings.shared_network ? "web-ports" : var.loadbalancer.visibility == "global" ? aws_security_group.product_sg_web_public[0].name : aws_security_group.product_sg_web_private[0].name
}

data "aws_security_group" "ecs-internal" {
    name = var.network_settings.shared_network ? "ecs-internal" : aws_security_group.ecs-internal[0].name
}

data "aws_security_group" "product_sg_app" {
    name = var.network_settings.shared_network ? "product-app-ports" : aws_security_group.product_sg_app[0].name
}

data "aws_security_group" "product_sg_redis" {
    name = var.network_settings.shared_network ? "product-redis-ports" : aws_security_group.product_sg_redis[0].name
}

data "aws_security_group" "product_sg_clamav" {
    name = var.network_settings.shared_network ? "clamav-ports" : aws_security_group.product_sg_clamav[0].name
}

data "aws_security_group" "product_sg_db" {
    name = var.network_settings.shared_network ? "db-ports" : aws_security_group.product_sg_db[0].name
}


