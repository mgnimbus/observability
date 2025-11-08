provider "grafana" {
  url  = "https://grafana.varidha.com"
  auth = "admin:gowthamm"
}

resource "grafana_organization" "obsrv" {
  name = "obsrv"
}

resource "grafana_data_source" "mimir" {
  name   = "Mimir"
  type   = "prometheus"
  url    = "http://mimir-mimir-nginx/prometheus"
  org_id = grafana_organization.obsrv.id
  http_headers = {
    X-Scope-OrgId = "obsrv"
  }
}

resource "grafana_data_source" "loki" {
  name   = "Loki"
  type   = "loki"
  url    = "http://loki-gateway.loki:80"
  org_id = grafana_organization.obsrv.id
  http_headers = {
    X-Scope-OrgId = "obsrv"
  }
}

resource "grafana_data_source" "tempo" {
  name   = "Tempo"
  type   = "tempo"
  url    = "http://tempo-distrubuted.tempo-query-frontend:3100"
  org_id = grafana_organization.obsrv.id
  http_headers = {
    X-Scope-OrgId = "obsrv"
  }
}
