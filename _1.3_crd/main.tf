resource "kubectl_manifest" "pod_monitor" {
  yaml_body         = file("${path.module}/manifests/pod-monitor.yaml")
  server_side_apply = true
  # ScrapeConfig is a large CRD (big OpenAPI schema). Server-side apply avoids the
  # client-side `last-applied-configuration` annotation that exceeds the 262144-byte
  # metadata.annotations limit.
}

resource "kubectl_manifest" "scrapeconfigs" {
  yaml_body         = file("${path.module}/manifests/scrapeconfigs.yaml")
  server_side_apply = true
  # ScrapeConfig is a large CRD (big OpenAPI schema). Server-side apply avoids the
  # client-side `last-applied-configuration` annotation that exceeds the 262144-byte
  # metadata.annotations limit.

}

resource "kubectl_manifest" "servicemonitors" {
  yaml_body         = file("${path.module}/manifests/servicemonitor.yaml")
  server_side_apply = true
  # ScrapeConfig is a large CRD (big OpenAPI schema). Server-side apply avoids the
  # client-side `last-applied-configuration` annotation that exceeds the 262144-byte
  # metadata.annotations limit.
}
