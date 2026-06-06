terraform {
  backend "s3" {
    bucket       = "observability-tfstate-bucky-ind"
    region       = "ap-south-2"
    key          = "s3_module/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
