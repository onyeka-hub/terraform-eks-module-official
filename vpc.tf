#
# VPC Resources
#  * VPC
#  * Subnets
#

resource "aws_vpc" "eks_cluster" {
  cidr_block = var.vpc_cidr

  tags = tomap({
    "Name"                                      = "terraform-eks-onyeka-node",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

# Get list of availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "eks_cluster" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eks_cluster.id

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-node",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_cluster.id

  tags = {
    Name = "onyeka-igw-terraform-eks"
  }
}

resource "aws_route_table" "eks_rtb" {
  vpc_id = aws_vpc.eks_cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
}

resource "aws_route_table_association" "eks_rtb_assoc" {
  count = 2

  subnet_id      = aws_subnet.eks_cluster.*.id[count.index]
  route_table_id = aws_route_table.eks_rtb.id
}
