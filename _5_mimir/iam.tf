
resource "aws_iam_policy" "mimir_irsa_s3_policy" {
  name        = "${local.name}-s3-policy"
  description = "To provide access to EKS to use AWS s3 services "

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "mimir_irsa_s3_role" {
  name = "${local.name}-s3-role-test"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${data.terraform_remote_state.eks.outputs.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub": "system:serviceaccount:${var.namespace}:${var.service_account_name}"
        }
      }
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "EKSAmazonS3Role" {
  policy_arn = aws_iam_policy.mimir_irsa_s3_policy.arn
  role       = aws_iam_role.mimir_irsa_s3_role.name
}
