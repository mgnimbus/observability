# Create AWS EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${local.name}-${var.cluster_name}"
  role_arn = aws_iam_role.eks_master_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = module.vpc.public_subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs

  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  # Enable EKS Cluster Control Plane Logging
  #enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
    module.vpc
  ]
  tags = {
    Name = "observability-test-eks"
  }
}

# module "eks_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 5.1.0"

#   name                = "${local.name}-eks-sg"
#   description         = "To open traffic to internet "
#   vpc_id              = module.vpc.vpc_id
#   ingress_rules       = ["ssh-tcp"]
#   ingress_cidr_blocks = ["0.0.0.0/0"]
#   egress_rules        = ["all-all"]
#   tags                = local.common_tags
# }

# Create AWS EKS Node Group - Public
# resource "aws_eks_node_group" "eks_ng_public" {
#   cluster_name = aws_eks_cluster.eks_cluster.name

#   node_group_name = "${local.name}-eks-ng-public"
#   node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
#   subnet_ids      = module.vpc.public_subnets
#   #version = var.cluster_version #(Optional: Defaults to EKS Cluster Kubernetes version)    

#   ami_type       = "AL2_x86_64" # BOTTLEROCKET_x86_64
#   capacity_type  = "ON_DEMAND"
#   disk_size      = 100
#   instance_types = ["t3.micro"] # t3a.large 


#   # remote_access {
#   #   ec2_ssh_key               = "eks-terraform-key"
#   #   source_security_group_ids = [module.eks_workernode_sg.security_group_id]

#   # }

#   scaling_config {
#     desired_size = 1
#     min_size     = 1
#     max_size     = 2
#   }

#   # Desired max percentage of unavailable worker nodes during node group update.
#   update_config {
#     max_unavailable = 1
#     #max_unavailable_percentage = 50    # ANY ONE TO USE
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
#   ]

#   tags = {
#     Name = "${local.name}-public-node-group"
#   }
# }

# module "eks_workernode_sg" {
#   source = "terraform-aws-modules/security-group/aws"
#   #version = "4.5.0"  
#   version = "4.17.2"

#   name        = "${local.name}-esk-workernode-sg"
#   description = "Security Group with SSH port open for everybody (IPv4 CIDR), egress ports are all world open"
#   vpc_id      = module.vpc.vpc_id
#   # Ingress Rules & CIDR Blocks
#   ingress_rules       = ["all-all"]
#   ingress_cidr_blocks = ["0.0.0.0/0"]
#   # Egress Rule - all-all open
#   egress_rules = ["all-all"]
#   tags         = local.common_tags
# }


# Create AWS EKS Node Group - Private

resource "aws_eks_node_group" "eks_ng_private" {
  cluster_name = aws_eks_cluster.eks_cluster.name

  node_group_name = "${local.name}-eks-ng-private"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = module.vpc.private_subnets
  #version = var.cluster_version #(Optional: Defaults to EKS Cluster Kubernetes version)    

  ami_type       = "BOTTLEROCKET_x86_64" # AL2_x86_64
  capacity_type  = "SPOT"
  disk_size      = 100
  instance_types = ["t4g.2xlarge"] # t3.medium 


  remote_access {
    ec2_ssh_key = "eks-terraform-key"
  }

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 3
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = 1
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
    module.vpc
  ]
  tags = {
    Name = "${local.name}-private-node-group"
  }
}

