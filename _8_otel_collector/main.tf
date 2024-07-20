
resource "helm_release" "otel-operator" {
  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "opentelemetry-collector"
  create_namespace = true

  values = [
    file("${path.module}/manifests/values.yaml")
  ]
  set {
    name  = "mode"
    value = "deployment"
  }
  set {
    name  = "image.repository"
    value = "otel/opentelemetry-collector-k8s"
  }
}

# resource "kubectl_manifest" "otel_col_ingress" {
#   depends_on = [helm_release.otel-operator]
#   yaml_body = templatefile("${path.module}/manifests/ingress.yaml", {
#     meda_domain_name = "varidha.com"
#     }
#   )
# }
