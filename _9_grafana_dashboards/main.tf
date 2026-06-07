locals {
  dashboard_root = "${path.module}/dashboards"

  dashboard_files = fileset(local.dashboard_root, "**/*.json")

  dashboard_folders = distinct([
    for f in local.dashboard_files : dirname(f)
  ])

  dashboards = {
    for f in local.dashboard_files :
    f => {
      folder = dirname(f)
      path   = "${local.dashboard_root}/${f}"
    }
  }
}

resource "grafana_folder" "folder" {
  for_each = toset(local.dashboard_folders)

  title = each.value
}

resource "grafana_dashboard" "dashboard" {
  for_each = local.dashboards

  config_json = file(each.value.path)

  folder = grafana_folder.folder[
    each.value.folder
  ].id

  overwrite = true
}
