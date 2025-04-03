
# output "eks_private_subnets" {
#   value = join(",", data.terraform_remote_state.eks.outputs.private_subnets)
# }

# # output "nginx_ingress_helm_metadata" {
# #   description = "Raw Metadata Block outlining status of the deployed release."
# #   value       = helm_release.nginx_ingress.metadata
# # }


# output "decoded_nginx_ingress_values" {
#   description = "Decoded values field from ingress-nginx Helm release metadata."
#   value       = jsondecode(helm_release.nginx_ingress.metadata[0].values)
# }

# output "nginx_ingress_helm_metadata" {
#   description = "Decoded Metadata Block outlining status of the deployed release."
#   value = {
#     app_version = helm_release.nginx_ingress.metadata[0].app_version
#     chart       = helm_release.nginx_ingress.metadata[0].chart
#     name        = helm_release.nginx_ingress.metadata[0].name
#     namespace   = helm_release.nginx_ingress.metadata[0].namespace
#     revision    = helm_release.nginx_ingress.metadata[0].revision
#     values      = jsondecode(helm_release.nginx_ingress.metadata[0].values)
#     version     = helm_release.nginx_ingress.metadata[0].version
#   }
# }
