
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 120
  version          = "6.27.0"
  # atomic           = true
  wait = false

  values = [
    templatefile("${path.module}/manifests/loki/test.yaml", {
      role_name          = "loki-sa"
      role_arn           = aws_iam_role.irsa_s3_role.arn
      loki_ruler_bucket  = data.terraform_remote_state.observability_buckets.outputs.observability_bucket_names["loki-ruler"]
      loki_chunks_bucket = data.terraform_remote_state.observability_buckets.outputs.observability_bucket_names["loki-chunks"]
      region             = "ap-south-2"
      }
  )]

}

