
output "observability_bucket_names" {
  description = "Name of the bucket"
  value       = { for i, k in aws_s3_bucket.observability : i => k.bucket }

}

data "terraform_remote_state" "observability_buckets" {
  backend = "s3"
  config = {
    bucket = "observability-tfstate-bucky-ind"
    key    = "s3_module/terraform.tfstate"
    region = var.region
  }
}
