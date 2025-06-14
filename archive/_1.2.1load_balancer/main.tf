# Install AWS ELB Controller using HELM
# Resource: Helm Release 
/*
resource "helm_release" "aws_lb_controller" {
  depends_on = [aws_iam_role.irsa_lbc_role]
  name       = "aws-load-balancer-controller"
  namespace  = var.namespace

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.ap-south-2.amazonaws.com/amazon/aws-load-balancer-controller"
    # Changes based on Region - This is for ap-south-2 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.irsa_lbc_role.arn
  }

  set {
    name  = "vpcId"
    value = data.terraform_remote_state.eks.outputs.vpc_id
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.eks.outputs.cluster_name
  }
}
*/
resource "helm_release" "aws_lb_controller" {
  name      = "aws-load-balancer-controller"
  namespace = var.namespace

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  values = [templatefile("${path.module}/manifests/values.yaml", {
    role_arn             = aws_iam_role.irsa_lbc_role.arn
    vpc_id               = data.terraform_remote_state.eks.outputs.vpc_id
    region               = var.region
    eks_cluster          = data.terraform_remote_state.eks.outputs.cluster_name
    service_account_name = var.service_account_name
  })]
}
