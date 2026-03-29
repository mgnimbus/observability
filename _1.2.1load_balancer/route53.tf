module "private_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"

  zones = {
    "otel.gowthamvandana_new.com" = {
      comment = "Private zone for EKS Cluster resources"
      vpc = [
        {
          vpc_id = data.terraform_remote_state.eks.outputs.vpc_id
        }
      ]
      private = true
      tags = {
        Environment = local.name
        Scope       = "InternalDNS"
      }
    }
  }
  tags = {
    ManagedBy = "Terraform"
    Project   = local.name
  }
  depends_on = [helm_release.aws_lb_controller]
}
