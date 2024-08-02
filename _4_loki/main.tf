
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "loki"
  create_namespace = true

  values = [
    templatefile("${path.module}/manifests/def.yaml", {

      }
  )]
  # set {
  #   name  = "service.type"
  #   value = "LoadBalancer"
  # }
}

