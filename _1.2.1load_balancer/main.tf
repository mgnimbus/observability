resource "helm_release" "aws_lb_controller" {
  name      = "aws-load-balancer-controller"
  namespace = var.namespace

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  values = [templatefile("${path.module}/manifests/values.yaml", {
    role_arn             = aws_iam_role.irsa_lbc_role.arn
    vpc_id               = data.terraform_remote_state.eks.outputs.vpc_id
    region               = var.aws_region
    eks_cluster          = data.terraform_remote_state.eks.outputs.cluster_name
    service_account_name = var.service_account_name
  })]
}
