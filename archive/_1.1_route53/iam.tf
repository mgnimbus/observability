
resource "aws_iam_policy" "irsa_r53_policy" {
  name        = "${local.name}-r53-policy"
  description = "To provide access to EKS to use AWS r53 services "

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "irsa_r53_role" {
  name = "${local.name}-r53-role-test"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${data.terraform_remote_state.eks.outputs.oidc_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:aud" : "sts.amazonaws.com",
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub" : "system:serviceaccount:${var.namespace}:external-dns"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "AllowExternalDNSUpdates"
  }
}



resource "aws_iam_role_policy_attachment" "EKSAmazonr53Role" {
  policy_arn = aws_iam_policy.irsa_r53_policy.arn
  role       = aws_iam_role.irsa_r53_role.name
}

