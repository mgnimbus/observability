module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  # Specify the subnets where Interface Endpoint ENIs should be created
  # Use the private subnets where your EKS nodes reside
  subnet_ids = module.vpc.private_subnets # <-- ADD THIS LINE

  # Use the dedicated SG for Interface Endpoints
  security_group_ids = [aws_security_group.vpc_ep_sg.id]

  endpoints = {
    # Interface Endpoints needed by EKS nodes
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-ecr-api-ep" }
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-ecr-dkr-ep" }
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-ec2-ep" }
      # Note: subnet_ids can sometimes be specified per-endpoint too,
      # but specifying at the top level is usually sufficient for this use case.
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-sts-ep" }
    },

    # S3 Endpoint - Gateway type (associates with route tables, not subnets directly here)
    s3_gateway = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids # Ensure this output exists and is correct
      tags            = { Name = "${local.name}-s3-gateway-ep" }
    }
    # Add other endpoints like 'logs' if needed
    # logs = { ... }
  }

  tags = merge(local.common_tags, { Name = "${local.name}-vpc-endpoints" })

  depends_on = [module.vpc]
}

# --- Ensure these supporting resources are correctly defined ---

# resource "aws_security_group" "vpc_ep_sg" { ... }
# data "aws_iam_policy_document" "generic_endpoint_policy" { ... } # (If used)
# Make sure the Node Security group allows outbound 443 to vpc_ep_sg
# Make sure vpc_ep_sg allows inbound 443 from the Node Security Group
resource "aws_security_group" "vpc_ep_sg" {
  name_prefix = "${local.name}-vpc_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = { Name = "vpc-endpoint-sg" }
}

# data "aws_iam_policy_document" "generic_endpoint_policy" {
#   statement {
#     effect    = "Deny"
#     actions   = ["*"]
#     resources = ["*"]

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }

#     condition {
#       test     = "StringNotEquals"
#       variable = "aws:SourceVpc"

#       values = [module.vpc.vpc_id]
#     }
#   }
# }
