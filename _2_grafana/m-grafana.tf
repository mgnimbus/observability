
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = var.namespace
  namespace        = "grafana"
  create_namespace = true

  values = [
    templatefile("${path.module}/manifests/default.yaml", {
      role_arn             = aws_iam_role.gafa_irsa_s3_role.arn
      service_account_name = var.service_account_name
      }
  )]
}

