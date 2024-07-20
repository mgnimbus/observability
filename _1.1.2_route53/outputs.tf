output "irsa_rs3_iam_role_arn" {
  description = "IRSA R53 IAM Role ARN"
  value       = aws_iam_role.irsa_r53_role.arn
}
