data "template_file" "service_account_yaml" {
  template = file("${path.module}/manifests/s3_sa.yml.tpl")

  vars = {
    irsa_s3_role_arn     = aws_iam_role.irsa_s3_role.arn
    service_account_name = var.service_account_name
    namespace            = var.namespace
  }
}

resource "local_file" "rendered_service_account_yaml" {
  content  = data.template_file.service_account_yaml.rendered
  filename = "${path.module}/manifests/s3_sa.yml"
}
