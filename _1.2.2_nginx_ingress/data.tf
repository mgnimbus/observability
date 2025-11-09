
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky-ind"
    key    = "eks_module_new/terraform.tfstate"
    region = var.region
  }
}

# Datasource: EKS Cluster Auth for helm
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_lbs" "otel" {
  tags = {
    "elbv2.k8s.aws/cluster" = data.terraform_remote_state.eks.outputs.cluster_name,
    "service.k8s.aws/stack" = "nginx-ingress/nginx-ingress-ingress-nginx-controller"
  }
}
