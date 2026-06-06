
resource "helm_release" "grafana_mcp" {
  name       = "grafana-mcp"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "grafana-mcp"
  namespace  = helm_release.grafana.metadata[0].namespace
  version    = "0.16.0"

  values = [
    file("${path.module}/manifests/mcp.yaml")
  ]
}
