
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "loki"
  create_namespace = true

  values = [
    "${file("${path.module}/manifests/loki/values.yaml")}"
  ]

}

