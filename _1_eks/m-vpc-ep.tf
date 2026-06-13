module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    # S3 Gateway endpoint — free, route-table-based. Keeps Loki/Mimir -> S3
    # traffic on a private, no-cost path. (Interface endpoints for ecr/ec2/sts
    # were removed: at $0.01/hr/ENI x 3 AZs they cost ~10x the NAT data they
    # would have saved on this low-traffic cluster; that traffic now rides the
    # existing NAT gateway.)
    s3_gateway = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${local.name}-s3-gateway-ep" }
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name}-vpc-endpoints" })

  depends_on = [module.vpc]
}
