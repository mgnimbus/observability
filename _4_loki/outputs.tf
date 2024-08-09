output "loki_helm_metadata" {
  description = "Decoded Metadata Block outlining status of the deployed release."
  value = {
    app_version = helm_release.loki.metadata[0].app_version
    chart       = helm_release.loki.metadata[0].chart
    name        = helm_release.loki.metadata[0].name
    namespace   = helm_release.loki.metadata[0].namespace
    revision    = helm_release.loki.metadata[0].revision
    values      = jsondecode(helm_release.loki.metadata[0].values)
    version     = helm_release.loki.metadata[0].version
  }
}
