resource "helm_release" "tempo" {
  name             = "tempo-distributed" # service names must match the datasource/OTel
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo-distributed" # was "grafana" (bug); single-binary values replaced
  namespace        = "tempo"
  version          = "1.61.3"
  create_namespace = true

  values = [
    templatefile("${path.module}/manifests/test.yaml", {
      role_arn = data.terraform_remote_state.s3.outputs.irsa_s3_iam_role_arn
      }
  )]
}
