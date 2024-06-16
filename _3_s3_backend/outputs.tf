output "irsa_s3_iam_role_arn" {
  description = "IRSA S3 IAM Role ARN"
  value       = aws_iam_role.irsa_s3_role.arn
}
