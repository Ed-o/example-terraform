resource "aws_vpc" "main" {
  cidr_block = "10.99.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

### Private Subnet

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.99.1.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "Private-subnet-B"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "Private-subnet-rt"
  }
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

### Public Subnet

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.99.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "Public-subnet-B"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public-subnet-rt"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "InternetGW"
  }
}

resource "aws_nat_gateway" "natgw" {
  subnet_id = aws_subnet.public_subnet.id
  allocation_id = aws_eip.vpn_eip.id
  tags = {
    Name = "NatGW"
  }
}



