# --- Configure VPC Endpoints Module ---
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  # Use the dedicated SG for Interface Endpoints
  security_group_ids = [aws_security_group.vpc_ep_sg.id]

  endpoints = {
    # Interface Endpoints needed by EKS nodes
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-ecr-api-ep" }
      # policy              = data.aws_iam_policy_document.generic_endpoint_policy.json # Optional
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-ecr-dkr-ep" }
      # policy              = data.aws_iam_policy_document.generic_endpoint_policy.json # Optional
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-ec2-ep" }
      # policy              = data.aws_iam_policy_document.generic_endpoint_policy.json # Optional
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      tags                = { Name = "${local.name}-sts-ep" }
      # policy              = data.aws_iam_policy_document.generic_endpoint_policy.json # Optional
    },

    # S3 Endpoint - Changed to Gateway type
    s3_gateway = {
      service      = "s3"
      service_type = "Gateway" # Correct type
      # No security_group_ids or private_dns_enabled needed for Gateway
      # Associate with private subnet route tables (module might do this, or use separate resource)
      route_table_ids = module.vpc.private_route_table_ids # Pass the private route table IDs from VPC module
      tags            = { Name = "${local.name}-s3-gateway-ep" }
      # policy          = data.aws_iam_policy_document.generic_endpoint_policy.json # Optional policy for Gateway endpoint
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name}-vpc-endpoints" })

  depends_on = [module.vpc, aws_security_group.vpc_ep_sg] # Depend on the SG
}

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
