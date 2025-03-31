resource "helm_release" "ingress_nginx" {
  name      = "nginx-ingress"
  namespace = var.nginx_namespace

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true

  values = [file("${path.module}/manifests/nginx/values.yaml")]

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.external.enabled"
    value = "false"
  }

  set {
    name  = "controller.service.internal.enabled"
    value = "true"
  }

  set {
    name  = "controller.service.internal.annotations.service\\.ingress\\.kubernetes\\.io/subnets"
    value = "{${join(",", var.private_subenets)}}"
  }

  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  depends_on = [helm_release.aws_lb_controller, aws_eks_node_group.eks_ng_private, kubectl_manifest.cert]
}


resource "kubectl_manifest" "cert" {
  yaml_body = file("${path.module}/manifests/nginx/certificate.yaml")
}

/*
aws ec2 create-tags --resources subnet-0697eef5bb5cb87cd subnet-0352fb45785fd0454 \                     ☁️  󱃾 nimbus 
    --tags Key=kubernetes.io/role/internal-elb,Value=1
aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/role/internal-elb"     
*/
