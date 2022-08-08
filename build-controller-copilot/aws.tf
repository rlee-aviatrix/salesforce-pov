provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.12.0.0/16"
  tags = {
    Name = "sharedsvcsdr12"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.12.0.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]
  tags = {
    Name = "sharedsvcsdr12-subnet"
  }
}

resource "aws_subnet" "subnet_ha" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.12.1.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[1]
  tags = {
    Name = "sharedsvcsdr12-subnet-ha"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "sharedsvcsdr12-igw"
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "sharedsvcsdr12-rtb"
  }
}

resource "aws_route_table_association" "rtb_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rtb_association_ha" {
  subnet_id      = aws_subnet.subnet_ha.id
  route_table_id = aws_route_table.rtb.id
}

resource "tls_private_key" "keypair_material" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = var.keypair
  public_key = tls_private_key.keypair_material.public_key_openssh
}