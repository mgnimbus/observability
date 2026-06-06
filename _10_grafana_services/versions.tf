terraform {
  backend "s3" {
    bucket       = "observability-tfstate-bucky-ind"
    region       = "ap-south-2"
    key          = "grafana_services/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "4.13.0"
    }
  }
}
