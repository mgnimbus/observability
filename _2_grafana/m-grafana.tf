
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "grafana"
  create_namespace = true

  values = [
    "${file("${path.module}/manifests/grafana_helm/default.yaml")}"
  ]
  set {
    name  = "nginx.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "nginx.service.port"
    value = "3000"
  }

}

# resource "kubectl_manifest" "grafana" {
#   depends_on = [helm_release.grafana]
#   yaml_body  = file("${path.module}/manifests/grafana_helm/service.yaml")
# }
