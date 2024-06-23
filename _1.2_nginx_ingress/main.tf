resource "helm_release" "ingress-nginx" {
  name      = "nginx-ingress"
  namespace = var.namespace

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true

  values = [file("${path.module}/manifests/values.yaml")]

  set {
    name  = "controller.replicaCount"
    value = "1"
  }
}


#  helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.publishService.enabled=true  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"