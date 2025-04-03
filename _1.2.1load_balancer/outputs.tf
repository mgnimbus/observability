output "irsa_aws_lbc_iam_role_arn" {
  description = "IRSA AWS LBC IAM Role ARN"
  value       = aws_iam_role.irsa_lbc_role.arn
}

# Helm Release Outputs
output "lbc_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value       = helm_release.aws_lb_controller.metadata
}

output "subii" {
  value = data.terraform_remote_state.eks.outputs.private_subnets
}
