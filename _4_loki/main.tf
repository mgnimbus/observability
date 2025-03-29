
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 120

  values = [
    templatefile("${path.module}/manifests/loki/test.yaml", {
      role_name          = "loki-sa"
      role_arn           = aws_iam_role.irsa_s3_role.arn
      loki_ruler_bucket  = "meda-dev-mackerel-loki-ruler"
      loki_chunks_bucket = "meda-dev-mackerel-loki-chunks"
      region             = "us-east-1"
      }
  )]

}

