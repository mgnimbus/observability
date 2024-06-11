locals {
  owners      = var.business_divsion
  environment = var.environment
  name        = "${var.business_divsion}-${var.environment}-${random_pet.randy.id}"
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    owners      = local.owners
    environment = local.environment
  }
  eks_cluster_name = data.terraform_remote_state.eks.outputs.cluster_id
}

resource "random_pet" "randy" {
  length = 1
}
