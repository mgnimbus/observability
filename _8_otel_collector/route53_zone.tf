data "aws_route53_zone" "otel" {
  name         = var.private_zone_name
  private_zone = true
}

locals {
  lb_arns = tolist(data.aws_lbs.otel.arns)
}

data "aws_lb" "selected" {
  for_each = { for idx, arn in local.lb_arns : "lb-${idx}" => arn }
  arn      = each.value
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
}

# Grafana

data "aws_lbs" "grafana" {
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
