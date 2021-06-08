################################
# VPC
################################
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

################################
# Internet Gateway
################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

################################
# Subnet
################################
data "aws_availability_zones" "az" {}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 11 + count.index) # 10.0.11.0/24, 10.0.12.0/24
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.prefix}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 21 + count.index) # 10.0.21.0/24, 10.0.22.0/24
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.prefix}-private-subnet-${count.index + 1}"
  }
}

################################
# Public Route Table
################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-public-route"
  }
}

resource "aws_route" "to_internet" {
  route_table_id         = aws_route_table.public_rt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_rt" {
  count          = length(aws_subnet.public.*.id)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

################################
# Private Route Table
################################
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-private-route"
  }
}

resource "aws_route_table_association" "private_rt" {
  count          = length(aws_subnet.private.*.id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
