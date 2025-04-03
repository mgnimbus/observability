resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = var.storage_class_name
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  depends_on          = [module.eks]
}

output "peks" {
  value = data.terraform_remote_state.eks.outputs
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky"
    key    = "eks_module/terraform.tfstate"
    region = var.aws_region
  }
}
