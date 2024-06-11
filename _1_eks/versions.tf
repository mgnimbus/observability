terraform {
  backend "s3" {
    bucket         = "nimbus-tfstate"
    region         = "us-east-1"
    key            = "eks_module/terraform.tfstate"
    dynamodb_table = "nimbus-state-lock"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.53.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
