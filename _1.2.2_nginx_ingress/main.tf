resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  namespace = kubernetes_namespace.nginx_ingress.metadata[0].name

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = false

  values = [file("${path.module}/manifests/default.yaml")]
  set {
    name  = "controller.service.internal.annotations.service\\.ingress\\.kubernetes\\.io/subnets"
    value = "{${join(",", data.terraform_remote_state.eks.outputs.private_subnets)}}"
  }
  depends_on = [kubernetes_secret.nginx_tls]
}

resource "kubernetes_secret" "nginx_tls" {
  metadata {
    name      = "nginx-ingress-tls"
    namespace = kubernetes_namespace.nginx_ingress.metadata[0].name
  }
  data = {
    "tls.crt" = filebase64("${path.module}/openssl/server/server.crt")
    "tls.key" = filebase64("${path.module}/openssl/server/server.key")
  }
  type = "kubernetes.io/tls"
}

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = var.namespace
  }
}
