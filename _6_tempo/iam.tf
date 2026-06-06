# IRSA role for Tempo S3 trace storage. Mirrors the loki/mimir pattern — each module owns
# its own role. (Previously _6_tempo referenced a non-existent remote-state output and
# iam.tf was empty, so tempo could never authenticate to S3.)

resource "aws_iam_policy" "tempo_irsa_s3_policy" {
  name        = "${local.name}-tempo-s3-policy"
  description = "S3 access for Tempo trace storage via IRSA"

  # s3:* on * mirrors the existing loki/mimir roles. Tighten to the tempo bucket ARNs
  # (arn:aws:s3:::meda-dev-mule-tempo-traces[/*]) if you want least-privilege.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "tempo_irsa_s3_role" {
  name = "${local.name}-tempo-s3-role"

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
          "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub": "system:serviceaccount:tempo:tempo-s3"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "tempo_s3" {
  policy_arn = aws_iam_policy.tempo_irsa_s3_policy.arn
  role       = aws_iam_role.tempo_irsa_s3_role.name
}
