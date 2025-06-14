
module "route53_zone" {
  depends_on = [helm_release.nginx_ingress]
  source     = "terraform-aws-modules/route53/aws//modules/zones"
  version    = "~> 5.0"

  # Define the zone name and make it private by associating to the default VPC
  zones = {
    "${var.privata_zone_name}" = {
      comment      = "Private hosted zone for observability"
      private_zone = true
      vpc = {
        vpc_id     = data.terraform_remote_state.eks.outputs.vpc_id
        vpc_region = var.region
      }
      tags = local.common_tags
    }
  }
}


locals {
  zone_name = sort(keys(module.route53_zone.route53_zone_zone_id))[0]
  lb_arns   = tolist(data.aws_lbs.obsrv.arns)
}

data "aws_lb" "selected" {
  for_each = { for idx, arn in local.lb_arns : "lb-${idx}" => arn }
  arn      = each.value
}


module "route53_records" {
  depends_on = [module.route53_zone]
  source     = "terraform-aws-modules/route53/aws//modules/records"
  version    = "~> 5.0"

  zone_name    = local.zone_name
  private_zone = true


  records = flatten([
    for lb in data.aws_lb.selected : [
      {
        name = ""
        type = "A"
        alias = {
          name                   = lb.dns_name
          zone_id                = lb.zone_id
          evaluate_target_health = true
        }
      },
      #   {
      #     name = "*"
      #     type = "A"
      #     alias = {
      #       name                   = lb.dns_name
      #       zone_id                = lb.zone_id
      #       evaluate_target_health = true
      #     }
      #   }
    ]
  ])
}
