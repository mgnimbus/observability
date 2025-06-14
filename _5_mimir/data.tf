
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky-ind"
    key    = "eks_module_new/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky-ind"
    key    = "s3_module/terraform.tfstate"
    region = var.region
  }
}

# Datasource: EKS Cluster Auth for helm
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "terraform_remote_state" "observability_buckets" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky-ind"
    key    = "s3_module/terraform.tfstate"
    region = var.region
  }
}
