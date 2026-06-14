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
    mimirtool = {
      source  = "ovh/mimirtool"
      version = "~> 1.0.0" # Use the latest suitable version
    }
  }
}

provider "grafana" {
  url = var.grafana_url

  auth = "${var.grafana_username}:${var.grafana_password}"
}

provider "mimirtool" {
  address   = "http://localhost:9009"
  tenant_id = "obsrv"
}
