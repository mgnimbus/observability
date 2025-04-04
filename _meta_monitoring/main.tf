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

  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "kube-state-metrics"
  namespace        = kubernetes_namespace.meta_monitoring.metadata[0].name
  version          = "3.5.7"
  create_namespace = false
  depends_on       = [helm_release.metrics_server]
}

resource "helm_release" "node_exporter" {
  name = "node-exporter"

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-node-exporter"
  version          = "4.45.0"
  create_namespace = false
  namespace        = kubernetes_namespace.meta_monitoring.metadata[0].name
}

resource "helm_release" "otel_meta_cop_logs" {
  name = "otel-meta-cop-logs"

  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = "0.119.1"
  create_namespace = false
  namespace        = kubernetes_namespace.meta_monitoring.metadata[0].name
  timeout          = 60
  values = [
    "${templatefile("${path.module}/manifests/otel_meta_cop_logs.yaml", {
      collector_id    = "obsrv-logs"
      eks_cluster     = data.terraform_remote_state.eks.outputs.cluster_name
      namespace       = kubernetes_namespace.meta_monitoring.metadata[0].name
      service_account = var.service_account_name
      # obsrv_domain_name = var.obsrv_domain_name
      # skip_tls_verify   = var.skip_tls_verify
    })}"
  ]
  depends_on = [kubernetes_secret_v1.otel_internal_ca]
}

resource "kubectl_manifest" "ta" {
  yaml_body = templatefile("${path.module}/manifests/meta_ta.yaml", {
    collector_id    = "obsrv-ta"
    eks_cluster     = data.terraform_remote_state.eks.outputs.cluster_name
    namespace       = kubernetes_namespace.meta_monitoring.metadata[0].name
    service_account = var.service_account_name
    # obsrv_domain_name = var.obsrv_domain_name
    # skip_tls_verify   = var.skip_tls_verify
  })
  depends_on = [kubernetes_secret_v1.otel_internal_ca]
}

resource "kubectl_manifest" "metrics" {
  yaml_body = templatefile("${path.module}/manifests/meta_metrics.yaml", {
    collector_id    = "obsrv-metrics"
    eks_cluster     = data.terraform_remote_state.eks.outputs.cluster_name
    namespace       = kubernetes_namespace.meta_monitoring.metadata[0].name
    service_account = var.service_account_name
    # obsrv_domain_name = var.obsrv_domain_name
    # skip_tls_verify   = var.skip_tls_verify

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
