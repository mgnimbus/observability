output "irsa_ca_iam_role_arn" {
  description = "IRSA ca IAM Role ARN"
  value       = aws_iam_role.irsa_ca_role.arn
}
