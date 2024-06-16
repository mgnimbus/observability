

resource "aws_iam_policy" "ebs_csi_irsa_policy" {
  name        = "${local.name}-ebs-policy"
  description = "To provide access to EKS to use AWS ebs services "

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AttachVolume",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DetachVolume",
          "ec2:ModifyVolume"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# default policy https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json

resource "aws_iam_role" "ebs_csi_iam_role" {
  name = "${local.name}-ebs-role-test"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "EBSRole" {
  policy_arn = aws_iam_policy.ebs_csi_irsa_policy.arn
  role       = aws_iam_role.ebs_csi_iam_role.name
}



resource "aws_iam_policy" "irsa_s3_policy" {
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

resource "aws_iam_role" "irsa_s3_role" {
  name = "${local.name}-s3-role-test"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn}:sub": "system:serviceaccount:${var.namespace}:${var.service_account_name}"
        }
      }
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "EKSAmazonS3Role" {
  policy_arn = aws_iam_policy.irsa_s3_policy.arn
  role       = aws_iam_role.irsa_s3_role.name
}
