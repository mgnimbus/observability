
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "nimbus-tfstate"
    key    = "eks_module/terraform.tfstate"
    region = var.region
  }
}

