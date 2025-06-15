# resource "kubectl_manifest" "alertmanager_config" {
#   yaml_body = file("${path.module}/manifests/alertmanager-config.yaml")
# }

# resource "kubectl_manifest" "alertmanager" {
#   yaml_body = file("${path.module}/manifests/alertmanager.yaml")
# }

# resource "kubectl_manifest" "otel_operator" {
#   yaml_body = file("${path.module}/manifests/opentelemetry-operator.yaml")
# }

# resource "kubectl_manifest" "prometheus_rules" {
#   yaml_body = file("${path.module}/manifests/prometheus-rules.yaml")
# }

resource "kubectl_manifest" "pod_monitor" {
  yaml_body = file("${path.module}/manifests/pod-monitor.yaml")
}


resource "kubectl_manifest" "service_monitor" {
  yaml_body = file("${path.module}/manifests/service-monitor.yaml")
}

resource "kubectl_manifest" "scrapeconfigs" {
  yaml_body = file("${path.module}/manifests/scrapeconfigs.yaml")
}
