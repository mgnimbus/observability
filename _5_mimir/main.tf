resource "helm_release" "mimir" {
  name             = "mimir"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "mimir-distributed"
  namespace        = "mimir"
  create_namespace = true
  timeout          = 120

  values = [
    templatefile("${path.module}/manifests/default.yaml", {
      role_arn = data.terraform_remote_state.s3.outputs.irsa_s3_iam_role_arn
      }
  )]

}

