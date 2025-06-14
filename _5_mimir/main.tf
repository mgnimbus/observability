resource "helm_release" "mimir" {
  name             = "mimir"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "mimir-distributed"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 300

  values = [
    templatefile("${path.module}/manifests/default.yaml", {
      role_arn             = aws_iam_role.mimir_irsa_s3_role.arn
      service_account_name = var.service_account_name
      mimir_chunks_bucket  = data.terraform_remote_state.observability_buckets.outputs.observability_bucket_names["mimir-chunks"]
      }
  )]

}

resource "kubectl_manifest" "ca_configmap" {
  yaml_body = file("${path.module}/manifests/ca.yaml")
}
