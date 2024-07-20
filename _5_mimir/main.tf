resource "helm_release" "mimir" {
  name             = "mimir"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "mimir"
  create_namespace = true

  values = [
    templatefile("${path.module}/manifests/test.yaml", {
      role_arn = data.terraform_remote_state.s3.outputs.irsa_s3_iam_role_arn
      }
  )]

}

