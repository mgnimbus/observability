terraform {
  backend "s3" {
    bucket       = "observability-tfstate-bucky-ind"
    region       = "ap-south-2"
    key          = "grafana-dashboards/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}

provider "grafana" {
  url = var.grafana_url

  auth = "${var.grafana_username}:${var.grafana_password}"
}
