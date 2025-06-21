module "efs" {
  depends_on = [ module.eks ]
  source = "terraform-aws-modules/efs/aws"
 # File system
  name           = "efs-eks"
  encrypted      = false

  # File system policy
  attach_policy                             = false
  deny_nonsecure_transport_via_mount_target = false
  bypass_policy_lockout_safety_check        = false

  # Mount targets / security group
  mount_targets              = { for k, v in zipmap(local.azs, module.vpc.private_subnets) : k => { subnet_id = v } }
  security_group_description = "Example EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  # Backup policy
  enable_backup_policy = false

  # Replication configuration
  create_replication_configuration = false

  tags = local.common_tags
}

resource "kubernetes_storage_class_v1" "efs_sc" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  depends_on          = [module.efs]
}

output "efs-id" {
  description = "The ID that identifies the file system (e.g., `fs-ccfc0d65`)"
  value       = module.efs.id
}

# output "mount_targets" {
#   description = "Map of mount targets created and their attributes"
#   value       = module.efs.mount_targets
# }