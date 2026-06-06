# RETIRED 2026-06-06 — superseded by Helm-native datasource/dashboard provisioning in
# _2_grafana/manifests/default.yaml. This module used the Grafana Terraform provider with a
# hardcoded admin credential and the public grafana.varidha.com URL; both are removed here.
# The old hardcoded admin credential remains in git history — ROTATE the Grafana admin
# password and scrub history (e.g. git filter-repo) if this repo is shared.
# This module is no longer applied (dropped from the deploy/destroy workflows).
provider "grafana" {
  alias = "retired"
  # url/auth intentionally removed — see note above.
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
