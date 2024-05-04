provider "aws" {
  region  = "us-east-1"
  
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "morningstar_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "morningstar_vpc"
    "kubernetes.io/cluster/morningstar_eks" = "shared"
  }
}

#Public Subnets
resource "aws_subnet" "public" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.morningstar_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                       = "morningstar_public_subnet"
    "kubernetes.io/cluster/morningstar_eks"         = "shared"
    "kubernetes.io/role/elb"                   = 1
  }
  
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.morningstar_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, count.index + var.availability_zones_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                       = "morningstar_private_subnet"
    "kubernetes.io/cluster/morningstar_eks"         = "shared"
    "kubernetes.io/role/elb"                   = 1
  }
}

# Internet Gateway
resource "aws_internet_gateway" "morningstar_igw" {
  vpc_id = aws_vpc.morningstar_vpc.id

  tags = {
    "Name" = "morningstar_igw"
  }

  depends_on = [aws_vpc.morningstar_vpc]
}

# NAT Elastic IP
resource "aws_eip" "main" {
  vpc        = true
  depends_on = [aws_internet_gateway.morningstar_igw]

  tags = {
    Name = "morningstar_ngw_ip"
  }
}

# NAT Gateway (public)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "morningstar_ngw"
  }
  depends_on = [aws_internet_gateway.morningstar_igw]
}

# Routing table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.morningstar_vpc.id

  tags = {
    Name = "morningstar_public_rt"
  }
}

# Routing table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.morningstar_vpc.id

  tags = {
    Name = "morningstar_private_rt"
  }
}

# Add route to route table
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.morningstar_igw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.public]
}

# Add route to route table
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.private]
}


# Route table and subnet associations
resource "aws_route_table_association" "public" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}



resource "aws_eks_cluster" "morningstar_eks" {
  name     = "morningstar_eks"
  version = "1.23"
  role_arn = aws_iam_role.cluster.arn
 
  vpc_config {
    subnet_ids = flatten([aws_subnet.public[*].id])
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
  
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}


# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "morningstar_eks_cluster_role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}



