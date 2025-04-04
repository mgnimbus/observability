
resource "helm_release" "otel_collector" {
  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = kubernetes_namespace.otel_collector.metadata[0].name
  create_namespace = true
  timeout          = 60
  version          = "0.109.0"

  values = [
    templatefile("${path.module}/manifests/values.yaml", {
      mimir_endpoint = "http://mimir-nginx.mimir.svc/api/vi/push"
      loki_endpoint  = "http://loki-gateway.loki.svc:80/loki/api/v1/push"
      tempo_endpoint = "http://tempo-distributed-distributor.tempo.svc.4317"
    })
  ]
  depends_on = [kubernetes_secret.otel_collector]
}

# exporters:
# otlphttp:
#   endpoint: http://<loki-addr>:3100/otlp

resource "kubectl_manifest" "ingress" {
  yaml_body = templatefile("${path.module}/manifests/ingress.yaml", {
    meda_domain_name = "gowthamvandana.com"
    }
  )
  depends_on = [helm_release.otel_collector]
}

resource "kubernetes_secret" "otel_collector" {
  metadata {
    name      = "otel-tls"
    namespace = kubernetes_namespace.otel_collector.metadata[0].name
  }
  data = {
    "tls.crt" = filebase64("${path.module}/server/server.crt")
    "tls.key" = filebase64("${path.module}/server/server.key")
  }
  type = "kubernetes.io/tls"
}

resource "kubernetes_namespace" "otel_collector" {
  metadata {
    name = "opentelemetry-collector"
  }
}
