locals {
  region = "eu-west-1"
  name   = "matrix"
}

provider "aws" {
  region                   = local.region
  shared_credentials_files = ["~/.aws/credentials"]
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Owner     = local.name
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  intra_subnets   = ["10.0.7.0/28", "10.0.7.16/28", "10.0.7.32/28"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.28.0"

  cluster_name = local.name

  # Enable private api server for worker node traffic to stay within VPC
  cluster_endpoint_private_access = true
  # Enable public api server for clients
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    // When we use the eks plugin, we do not have to manually update the aws-node role or daemon set
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.irsa_vpc_cni.iam_role_arn
    }
  }

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols ingress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Node to node all ports/protocols egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      self        = true
    }
    egress_beyond = {
      description = "Go outside"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  node_security_group_additional_rules = {}

  cluster_enabled_log_types = []
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets

  eks_managed_node_group_defaults = {}

  eks_managed_node_groups = {
    worker = {
      create_launch_template = false
      launch_template_name   = ""
      min_size               = 1
      max_size               = 10
      desired_size           = 1
      instance_types         = ["m5a.xlarge"]
      subnet_ids             = module.vpc.private_subnets
      disk_size              = 50
      labels = {
        group = "worker"
      }
      update_config = {
        max_unavailable = 3
      }
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::myaccount:user/myuser@mycompany.com"
      username = "myuser"
      groups   = ["system:masters"]
    }
  ]
}

# Keep this module in this file, because it is needed by the plugin defined in the block above
module "irsa_vpc_cni" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.2.0"

  role_name = "vpc-cni"
  role_path = "/${module.eks.cluster_id}/irsa/"

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}
