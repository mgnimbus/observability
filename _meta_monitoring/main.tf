resource "kubernetes_namespace" "meta_monitoring" {
  metadata {
    name = var.namespace
  }
}


resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  chart            = "metrics-server"
  namespace        = kubernetes_namespace.meta_monitoring.metadata[0].name
  version          = "3.12.2"
  create_namespace = false
}

resource "helm_release" "kube_state_metrics" {
  name = "kube-state-metrics"

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-state-metrics"
  namespace        = kubernetes_namespace.meta_monitoring.metadata[0].name
  version          = "6.2.0"
  create_namespace = false
  values           = [file("${path.module}/manifests/ksm-values.yaml")]
  depends_on       = [helm_release.metrics_server]
}

resource "helm_release" "node_exporter" {
  name = "node-exporter"

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-node-exporter"
  version          = "4.55.0"
  create_namespace = false
  namespace        = kubernetes_namespace.meta_monitoring.metadata[0].name

  # Uniform values-file pattern (matches kube_state_metrics above). De-annotation + ServiceMonitor +
  # the Topic-8 collector/cardinality cleanup (dead/unconsumed collectors disabled, per-mount &
  # per-eni excludes, unconsumed node_memory_* dropped) all live in this one file.
  values = [file("${path.module}/manifests/node-exporter-values.yaml")]
}

# Node-local container-log tail -> Loki. Operator CR (was the Helm opentelemetry-collector chart),
# now uniform with the other meta collectors: explicit config (no chart presets / label explosion),
# and its :8888 self-telemetry is covered by the collector-self ServiceMonitor (no PodMonitor).
resource "kubectl_manifest" "logs" {
  yaml_body = templatefile("${path.module}/manifests/meta_logs.yaml", {
    collector_id      = "obsrv-logs"
    eks_cluster       = data.terraform_remote_state.eks.outputs.cluster_name
    namespace         = kubernetes_namespace.meta_monitoring.metadata[0].name
    service_account   = var.service_account_name
    obsrv_domain_name = var.obsrv_domain_name
    skip_tls_verify   = var.skip_tls_verify
    tenant            = var.tenant
  })
  depends_on = [kubernetes_secret_v1.otel_internal_ca]
}

resource "kubectl_manifest" "ta" {
  yaml_body = templatefile("${path.module}/manifests/meta_ta.yaml", {
    collector_id      = "obsrv-ta"
    eks_cluster       = data.terraform_remote_state.eks.outputs.cluster_name
    namespace         = kubernetes_namespace.meta_monitoring.metadata[0].name
    service_account   = var.service_account_name
    version           = "0.120.1"
    obsrv_domain_name = var.obsrv_domain_name
    skip_tls_verify   = var.skip_tls_verify
    tenant            = var.tenant
  })
  depends_on = [kubernetes_secret_v1.otel_internal_ca]
}


resource "kubectl_manifest" "metrics" {
  yaml_body = templatefile("${path.module}/manifests/meta_metrics.yaml", {
    collector_id      = "obsrv-metrics-new"
    eks_cluster       = data.terraform_remote_state.eks.outputs.cluster_name
    namespace         = kubernetes_namespace.meta_monitoring.metadata[0].name
    service_account   = var.service_account_name
    obsrv_domain_name = var.obsrv_domain_name
    skip_tls_verify   = var.skip_tls_verify
    tenant            = var.tenant
  })
  depends_on = [kubernetes_secret_v1.otel_internal_ca]
}


# Cluster-scoped Kubernetes Events -> Loki. Singleton deployment (events are not node-local; >1 replica
# duplicates every event). Reuses otel-ta-sa (events list/watch in the ClusterRole). Its :8888
# self-telemetry is covered by the collector-self ServiceMonitor.
resource "kubectl_manifest" "events" {
  yaml_body = templatefile("${path.module}/manifests/meta_events.yaml", {
    collector_id      = "obsrv-events"
    eks_cluster       = data.terraform_remote_state.eks.outputs.cluster_name
    namespace         = kubernetes_namespace.meta_monitoring.metadata[0].name
    service_account   = var.service_account_name
    obsrv_domain_name = var.obsrv_domain_name
    skip_tls_verify   = var.skip_tls_verify
    tenant            = var.tenant
  })
  depends_on = [kubernetes_secret_v1.otel_internal_ca]
}

resource "kubectl_manifest" "serviceaccount" {
  yaml_body = file("${path.module}/manifests/serviceaccount.yaml")
}

resource "kubectl_manifest" "clusterrole" {
  yaml_body = file("${path.module}/manifests/clusterrole.yaml")
}

resource "kubectl_manifest" "clusterrolebinding" {
  yaml_body = file("${path.module}/manifests/clusterrolebinding.yaml")
}

# ServiceMonitor for EKS CoreDNS (the kube-dns Service already exposes a named `metrics` port :9153).
# Replaces the annotation-based kubernetes-service-endpoints scrape: kube-dns keeps its EKS-managed
# prometheus.io/scrape annotation, so that job was removed from meta_metrics.yaml to avoid a double-scrape.
resource "kubectl_manifest" "coredns_servicemonitor" {
  yaml_body = file("${path.module}/manifests/coredns-servicemonitor.yaml")
}

# ServiceMonitor scraping the operator collectors' :8888 self-telemetry (otelcol_*). The operator emits
# *-collector-monitoring Services from enableMetrics:true but no ServiceMonitor (its
# observability.prometheus feature gate is off). Covers all four meta collectors — ta, metrics-new,
# events, and logs (now an operator CR too). Discovered by the match-all prometheusCR TA.
resource "kubectl_manifest" "collector_self_servicemonitor" {
  yaml_body = templatefile("${path.module}/manifests/collector-self-servicemonitor.yaml", {
    namespace = kubernetes_namespace.meta_monitoring.metadata[0].name
  })
}

# Secret containing the CA cert for internal clients to trust the server
resource "kubernetes_secret_v1" "otel_internal_ca" {
  metadata {
    name      = "otel-internal-ca-secret"
    namespace = kubernetes_namespace.meta_monitoring.metadata[0].name
  }
  type = "Opaque"
  data = {
    "ca.crt" = filebase64("${path.module}/manifests/ca.crt")
  }
}
