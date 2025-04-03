
resource "helm_release" "otel-operator" {
  name             = "opentelemetry-operator"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-operator"
  namespace        = "opentelemetry-operator"
  create_namespace = true

  set {
    name  = "manager.collectorImage.repository"
    value = "ghcr.io/open-telemetry/opentelemetry-operator/opentelemetry-operator"
  }
  set {
    name  = "crds.create"
    value = "true"
  }
}
