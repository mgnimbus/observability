resource "helm_release" "tempo" {
  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "tempo"
  create_namespace = true

  values = [
    templatefile("${path.module}/manifests/test.yaml", {
      role_arn = data.terraform_remote_state.s3.outputs.irsa_s3_iam_role_arn
      }
  )]
}

resource "kubectl_manifest" "ca_configmap" {
  yaml_body = file("${path.module}/manifests/ca.yaml")
}
