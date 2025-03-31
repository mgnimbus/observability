
resource "helm_release" "otel_collector" {
  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "opentelemetry-collector"
  create_namespace = true
  timeout          = 60

  values = [
    templatefile("${path.module}/manifests/values.yaml", {
      mimir_endpoint = "http://mimir-nginx.mimir.svc/api/vi/push"
      loki_endpoint  = "http://loki-gateway.loki.svc:80/loki/api/v1/push"
      tempo_endpoint = "http://tempo-distributed-distributor.tempo.svc.4317"
    })
  ]
}

resource "kubectl_manifest" "ingress" {
  depends_on = [helm_release.otel_collector]
  yaml_body = templatefile("${path.module}/manifests/ingress.yaml", {
    meda_domain_name = "varidha.com"
    }
  )
}
