resource "kubectl_manifest" "autoscaler" {
  yaml_body = templatefile("${path.module}/manifests/sa_ca.yaml", {
    role_arn = aws_iam_role.irsa_ca_role.arn
    sa_name  = var.service_account_name
    ns       = var.namespace
    }
  )
}
