# To get the eks cluster details
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky"
    key    = "eks_module/terraform.tfstate"
    region = var.region
  }
}

# Datasource: EKS Cluster Auth for helm
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}
