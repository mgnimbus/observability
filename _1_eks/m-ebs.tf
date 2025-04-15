resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = var.storage_class_name
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  depends_on          = [module.eks]
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky"
    key    = "eks_module_new/terraform.tfstate"
    region = var.aws_region
  }
}
