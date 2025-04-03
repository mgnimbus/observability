module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name}-${var.cluster_name}"
  cluster_version = "1.30"

  # EKS Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      service_account_role_arn = module.irsa_vpc_cni.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa_ebs_csi.iam_role_arn
    }
  }
  # Add this block to grant 'nimbus' user access
  access_entries = {
    nimbus_user_access = {
      principal_arn = "arn:aws:iam::058264194719:user/nimbus"
      username      = "nimbus"
      groups        = ["system:masters"]
    }
  }

  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  eks_managed_node_groups = {
    use_custom_launch_template = false
    obsrv = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3a.large"]
      iam_role_arn   = aws_iam_role.eks-nodegroup-role.arn

      min_size     = 2
      max_size     = 3
      desired_size = 2

      #     bootstrap_extra_args = <<-EOT
      #       # The admin host container provides SSH access and runs with "superpowers".
      #       # It is disabled by default, but can be disabled explicitly.
      #       [settings.host-containers.admin]
      #       enabled = false

      #       # The control host container provides out-of-band access via SSM.
      #       # It is enabled by default, and can be disabled if you do not expect to use SSM.
      #       # This could leave you with no way to access the API and change settings on an existing node!
      #       [settings.host-containers.control]
      #       enabled = true

      #       # extra args added
      #       [settings.kernel]
      #       lockdown = "integrity"
      #     EOT
    }
  }
  tags = local.common_tags
}


# resource "aws_security_group" "remote_access" {
#   name_prefix = "${local.name}-remote-access"
#   description = "Allow remote SSH access"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "SSH access"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/8"]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = merge(local.common_tags, { Name = "${local.name}-remote" })
# }

# data "aws_ami" "eks_default_bottlerocket" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["bottlerocket-aws-k8s-${var.cluster_version}-x86_64-*"]
#   }
# }
