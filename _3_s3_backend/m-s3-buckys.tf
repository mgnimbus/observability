resource "aws_s3_bucket" "observability" {
  for_each = toset(local.observability_buckets)
  bucket   = "${local.name}-${each.value}"

  tags = {
    Name        = "${each.value}-backend"
    Environment = "Dev"
  }
}

locals {
  observability_buckets = [
    "loki-index",
    "loki-chunks",
    "loki-ruler"
  ]
}

resource "aws_s3_bucket_policy" "allow_access_from_observability" {
  for_each = toset(local.observability_buckets)
  bucket   = aws_s3_bucket.observability[each.value].id
  policy   = data.aws_iam_policy_document.allow_access_from_observability[each.value].json
}

data "aws_iam_policy_document" "allow_access_from_observability" {
  for_each = toset(local.observability_buckets)
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.irsa_s3_role.arn]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.observability[each.value].arn,
      "${aws_s3_bucket.observability[each.value].arn}/*",
    ]
  }
}
