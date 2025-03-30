# resource "kubectl_manifest" "pod_monitor" {
#   yaml_body = templatefile("${path.module}/manifests/s3_sa.yml", {
#     irsa_s3_role_arn     = aws_iam_role.irsa_s3_role.arn
#     service_account_name = var.service_account_name
#     namespace            = var.namespace
#   })
# }
