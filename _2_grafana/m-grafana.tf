
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = var.namespace
  namespace        = "grafana"
  create_namespace = true

  values = [
    templatefile("${path.module}/manifests/default.yaml", {
      role_arn             = aws_iam_role.gafa_irsa_s3_role.arn
      service_account_name = var.service_account_name
      }
  )]
}


resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.grafana]

  create_duration = "60s"
}

data "aws_lbs" "grafana" {
  depends_on = [helm_release.helm_release, time_sleep.wait_30_seconds]
  tags = {
    "elbv2.k8s.aws/cluster" = data.terraform_remote_state.eks.outputs.cluster_name,
    "ingress.k8s.aws/stack" = "grafana/grafana"
  }
}

locals {
  lb_arns = tolist(data.aws_lbs.grafana.arns)
}


data "aws_lb" "selected" {
  for_each = { for idx, arn in local.lb_arns : "lb-${idx}" => arn }
  arn      = each.value
}

resource "aws_route53_record" "otel" {
  name    = "grafana"
  type    = "A"
  zone_id = "Z0337659CJX6TAYBFWV4"
  alias {
    name                   = data.aws_lb.selected["lb-0"].dns_name
    zone_id                = data.aws_lb.selected["lb-0"].zone_id
    evaluate_target_health = true
  }
}
