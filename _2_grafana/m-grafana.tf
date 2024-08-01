
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "grafana"
  create_namespace = true

  values = [
    "${file("${path.module}/manifests/default.yaml")}"
  ]

}

