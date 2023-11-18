variable "aws_region" {
  default = "us-east-2"
}

variable "cluster_name" {
  default = "onyeka-eks-18-31-0"
  type    = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}