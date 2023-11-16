resource "aws_vpc" "zabbix_vpc" {
  count = var.network_settings.shared_network ? 0 : 1    # Only make VPC if not shared
  cidr_block = var.network_settings["vpc_cidr"]
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags = {
    Name                = "zabbix-vpc"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

data "aws_vpc" "selected" {
  id = var.network_settings.shared_network ? var.network_settings.vpc_id : aws_vpc.zabbix_vpc[0].id
}

resource "aws_subnet" "zabbix_private_subnets" {
  for_each = var.network_subnets
  vpc_id                = "${data.aws_vpc.selected.id}"
  cidr_block            = format("%s%s", var.network_settings.vpc_cidr_base, each.value.private_cidr_range)
  availability_zone     = format("%s%s", var.network_settings.region, each.value.availability_zone)
  tags = {
    Name                = "${each.value.name}-private"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_subnet" "zabbix_public_subnets" {
  for_each = var.network_subnets
  vpc_id                = "${data.aws_vpc.selected.id}"
  cidr_block            = format("%s%s", var.network_settings.vpc_cidr_base, each.value.public_cidr_range)
  availability_zone     = format("%s%s", var.network_settings.region, each.value.availability_zone)
  tags = {
    Name                = "${each.value.name}-public"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_internet_gateway" "zabbix_internet_gateway" {
  count         = var.network_settings.shared_network ? 0 : 1    # Only make VPC if not shared
  vpc_id        = "${data.aws_vpc.selected.id}"
  tags          = {
    Name                = "zabbix-internetgw"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

data "aws_internet_gateway" "zabbix_internet_gateway" {
  filter {
    name   = "attachment.vpc-id"
    values = [ "${data.aws_vpc.selected.id}" ]
  }
}

resource "aws_nat_gateway" "zabbix_nat_gateway" {
  for_each = var.network_subnets
  subnet_id = aws_subnet.zabbix_public_subnets[each.key].id
  allocation_id = aws_eip.eip[each.key].id
  tags = {
    Name = "zabbix-natgw"
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_eip" "eip" {
  for_each = var.network_subnets
  tags = {
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_route_table" "routetable_public" {
  vpc_id = "${data.aws_vpc.selected.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.zabbix_internet_gateway.id}"
  }
  tags = {
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_route_table_association" "routetable_public_associaction" {
  for_each = var.network_subnets
  subnet_id      = aws_subnet.zabbix_public_subnets[each.key].id
  route_table_id = aws_route_table.routetable_public.id
}

resource "aws_route_table" "routetable_private" {
  for_each = var.network_subnets
  vpc_id = "${data.aws_vpc.selected.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.zabbix_nat_gateway[each.key].id
  }
  tags = {
    environment         = var.setup.environment
    creator             = var.setup.creator
    asset               = "network"
  }
}

resource "aws_route_table_association" "routetable_private_associaction" {
  for_each = var.network_subnets
  subnet_id = aws_subnet.zabbix_private_subnets[each.key].id
  route_table_id = aws_route_table.routetable_private[each.key].id
}

