
resource "helm_release" "otel-operator" {
  name             = "opentelemetry-operator"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-operator"
  namespace        = "opentelemetry-operator"
  create_namespace = true

  values = [
    file("${path.module}/manifests/values.yaml")
  ]

  set {
    name  = "manager.collectorImage.repository"
    value = "tel/opentelemetry-collector-k8s"
  }
  set {
    name  = "admissionWebhooks.certManager.enabled"
    value = "false"
  }
  set {
    name  = "admissionWebhooks.autoGenerateCert.enabled"
    value = "true"
  }
}

