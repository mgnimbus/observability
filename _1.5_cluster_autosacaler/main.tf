resource "kubectl_manifest" "autoscaler" {
  yaml_body = template_file("${path.module}/manifests/sa_ca.yml", {
    role_arn  = aws_iam_role.irsa_ca_role.arn
    role_name = aws_iam_role.irsa_ca_role.name
    sa_name   = ""
    ns        = var.namespace

    }
  )
}
