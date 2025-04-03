resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = var.storage_class_name
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  depends_on          = [module.eks]
}
