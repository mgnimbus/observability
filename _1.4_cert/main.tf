resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [kubectl_manifest.zues_tls_secret]
}

resource "kubectl_manifest" "zues_tls_secret" {
  yaml_body = file("${path.module}/manifests/zues_cert.yaml")
}

resource "kubectl_manifest" "metrics" {
  yaml_body  = file("${path.module}/manifests/certificate.yaml")
  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "issuer" {
  yaml_body  = file("${path.module}/manifests/issuer.yaml")
  depends_on = [helm_release.cert_manager]
}
