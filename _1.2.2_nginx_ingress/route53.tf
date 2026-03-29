data "aws_route53_zone" "otel" {
  name         = var.private_zone_name
  private_zone = true
  depends_on   = [helm_release.nginx_ingress]
}

locals {
  lb_arns = tolist(data.aws_lbs.otel.arns)
}

data "aws_lb" "selected" {
  for_each   = { for idx, arn in local.lb_arns : "lb-${idx}" => arn }
  arn        = each.value
  depends_on = [helm_release.nginx_ingress]
}


resource "aws_route53_record" "otel" {
  name    = var.private_zone_name
  type    = "A"
  zone_id = data.aws_route53_zone.otel.zone_id
  alias {
    name                   = data.aws_lb.selected[keys(data.aws_lb.selected)[0]].dns_name
    zone_id                = data.aws_lb.selected[keys(data.aws_lb.selected)[0]].zone_id
    evaluate_target_health = true
  }
  depends_on = [helm_release.nginx_ingress]
}
