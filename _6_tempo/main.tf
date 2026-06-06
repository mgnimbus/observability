resource "helm_release" "tempo" {
  name             = "tempo-distributed" # service names must match the datasource/OTel
  repository       = "https://grafana-community.github.io/helm-charts"
  chart            = "tempo-distributed" # was "grafana" (bug); single-binary values replaced
  namespace        = "tempo"
  version          = "2.1.2"
  create_namespace = true

  values = [
    templatefile("${path.module}/manifests/test.yaml", {
      role_arn = aws_iam_role.tempo_irsa_s3_role.arn
      }
  )]
}
