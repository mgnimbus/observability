
output "cluster_id" {
  description = "The name/id of the EKS cluster."
  value       = data.terraform_remote_state.eks.outputs.cluster_id
}

output "ebs_csi_driver" {
  value = helm_release.ebs_csi_driver.metadata
}
