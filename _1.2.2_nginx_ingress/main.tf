resource "helm_release" "ingress-nginx" {
  name      = "nginx-ingress"
  namespace = var.namespace

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true

  values = [file("${path.module}/manifests/default.yaml")]

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "controller.replicaCount"
    value = "1"
  }
  set {
    name  = "controller.service.internal.annotations.service\\.ingress\\.kubernetes\\.io/subnets"
    value = yamlencode(data.terraform_remote_state.eks.outputs.private_subnets)
  }

}


#  helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.publishService.enabled=true  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"
