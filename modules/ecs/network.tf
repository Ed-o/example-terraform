resource "aws_vpc" "product_vpc" {
  count = var.network_settings.shared_network ? 0 : 1    # Only make VPC if not shared
  cidr_block = var.network_settings["vpc_cidr"]
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags = {
    Name                = "product-vpc" 
    environment		= var.setup.environment
    creator 		= var.setup.creator
    asset 		= "network"
  }
}

data "aws_vpc" "selected" {
  id = var.network_settings.shared_network ? var.network_settings.vpc_id : aws_vpc.product_vpc[0].id
}

# For the logs inside, lets get an extra name if they are in a shared env like dev
locals {
  sharedname = var.network_settings.shared_network ? "-${var.setup.name}" : ""
  subnetname = var.network_settings.shared_network ? "${var.setup.name}-" : ""
}

resource "aws_subnet" "subnet_private" {
  for_each = var.network_subnets.new
  vpc_id            	= "${data.aws_vpc.selected.id}"
  cidr_block		= format("%s%s", var.network_settings.vpc_cidr_base, each.value.private_cidr_range)
  availability_zone 	= format("%s%s", var.network_settings.region, each.value.availability_zone)
  tags = {
    Name		= "${local.subnetname}${each.value.name}-private"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  } 
}

locals {
  subnet_public = var.network_settings.shared_network ? [for subnet in var.network_subnets.public : tostring(subnet.id)] : [for subnet in aws_subnet.subnet_public : tostring(subnet.id)]
  subnet_private = var.network_settings.shared_network ? [for subnet in var.network_subnets.private : tostring(subnet.id)] : [for subnet in aws_subnet.subnet_private : tostring(subnet.id)]
  subnet_selected = var.software.nginx.enabled ? local.subnet_private : local.subnet_public 
}

resource "aws_subnet" "subnet_public" {
  for_each = var.network_subnets.new
  vpc_id            	= "${data.aws_vpc.selected.id}"
  cidr_block		= format("%s%s", var.network_settings.vpc_cidr_base, each.value.public_cidr_range)
  availability_zone 	= format("%s%s", var.network_settings.region, each.value.availability_zone)
  tags = {
    Name		= "${local.subnetname}${each.value.name}-public"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_internet_gateway" "product_internet_gateway" {
  count		= var.network_settings.shared_network ? 0 : 1    # Only make if not shared
  vpc_id	= "${data.aws_vpc.selected.id}"
  tags 		= {
    Name 		= "internetgw"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

data "aws_internet_gateway" "product_internet_gateway" {
  filter {
    name   = "attachment.vpc-id"
    values = [ "${data.aws_vpc.selected.id}" ]
  }
}

resource "aws_nat_gateway" "product_nat_gateway" {
  for_each = var.network_subnets.new
  subnet_id = aws_subnet.subnet_public[each.key].id
  allocation_id = aws_eip.eip[each.key].id
  tags = {
    Name 		= "natgw-${aws_subnet.subnet_public[each.key].availability_zone}"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_eip" "eip" {
  for_each = var.network_subnets.new
  tags = {
    Name		= "natgw-${each.value.availability_zone}-eip"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_route_table" "routetable_public" {
  count		= var.network_settings.shared_network ? 0 : 1    # Only make if not shared
  vpc_id = "${data.aws_vpc.selected.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.product_internet_gateway.id}"
  }
  lifecycle {
    ignore_changes = [route]
  }
  tags = {
    Name		= "rt-${var.setup.name}-public"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_route_table_association" "routetable_public_associaction" {
  for_each = var.network_subnets.new
  subnet_id      = aws_subnet.subnet_public[each.key].id
  route_table_id = aws_route_table.routetable_public[0].id
}

resource "aws_route_table" "routetable_private" {
  for_each = var.network_subnets.new
  vpc_id = "${data.aws_vpc.selected.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.product_nat_gateway[each.key].id
  }
  lifecycle {
    ignore_changes = [route]
  }
  tags = {
    Name		= "rt-${var.setup.name}-private"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_route_table_association" "routetable_private_associaction" {
  for_each = var.network_subnets.new
  subnet_id = aws_subnet.subnet_private[each.key].id
  route_table_id = aws_route_table.routetable_private[each.key].id
}

