# VPC module
# KMS module
# Kubernetes components - https://kubernetes.io/docs/concepts/overview/components/#:~:text=kube%2Dproxy%20is%20a%20network,or%20outside%20of%20your%20cluster.
# Add-ons
# coredns - https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
# vpc-cni - https://docs.amazonaws.cn/en_us/eks/latest/userguide/cni-iam-role.html
# Node Groups & Fargate configuration 
# Taints and tolerations are a mechanism that allows you to ensure that pods are not placed on inappropriate nodes. Taints are added to nodes, while tolerations are defined in the pod specification
# For example, most Kubernetes distributions will automatically taint the master nodes so that one of the pods that manages the control plane is scheduled onto them and not any other data plane pods deployed by users
# kubectl taint nodes nodename activeEnv=green:NoSchedule
# tolerations:
# - effect: NoSchedule
#   key: activeEnv
#   operator: Equal
#   value: green
# Update kubeconfig to connect to the EKS cluster
# aws eks update-kubeconfig --name masterclass-cluster --region eu-west-2 --kubeconfig ~/.kube/config --profile masterclass
# kubectl config get-contexts 
# kubectl config use-context arn:aws:eks:eu-west-2:832611670348:cluster/masterclass-cluster

############# Provider & Backend #############
########################################

provider "aws" {
  region = var.aws_region
}

############# Data Sources #############
########################################
data "aws_eks_cluster" "default" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}


############# Encryption key #############
########################################
resource "aws_kms_key" "eks_cluster_key" {
  description = "onyeka EKS Secret Encryption Key"
}

############# EKS #############
########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.23"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks_cluster_key.arn
    resources        = ["secrets"]
  }]

  #TODO Use data source or interpolate from another module
  vpc_id     = aws_vpc.eks_cluster.id
  subnet_ids = [aws_subnet.eks_cluster[0].id, aws_subnet.eks_cluster[1].id]

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "m6i.large"
    update_launch_template_default_version = true
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }

  self_managed_node_groups = {
    one = {
      name         = "mixed-1"
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "m5.large"
            weighted_capacity = "1"
          },
          {
            instance_type     = "m6i.large"
            weighted_capacity = "2"
          },
        ]
      }
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["t3.large", "m5.large"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true
  #   create_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::958217526797:role/s3_Admin_access"
      username = "LambdaToS3"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::958217526797:user/onyeka"
      username = "onyeka"
      groups   = ["system:masters"]
    },
  ]

  #   aws_auth_accounts = [
  #     "777777777777",
  #     "888888888888",
  #   ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}