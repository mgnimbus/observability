# resource "aws_iam_role_policy" "eks_admin_policy" {
#   name = "${local.name}-eks-full-access-policy"
#   role = aws_iam_role.eks_admin_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "iam:ListRoles",
#           "eks:*",
#           "ssm:GetParameter"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }

# resource "aws_iam_role" "eks_admin_role" {
#   name = "${local.name}-eks-full-access-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           AWS = "arn:aws:iam::${var.account_id}:root"
#         }
#       },
#     ]
#   })
# }


# resource "aws_iam_group_policy" "eks_developer_policy" {
#   name  = "eks_admins_policy"
#   group = aws_iam_group.eks_developers.name

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "sts:AssumeRole*",
#         ]
#         Effect   = "Allow"
#         Resource = "${aws_iam_role.eks_admin_role.id}"
#       },
#     ]
#   })
# }

# resource "aws_iam_group" "eks_developers" {
#   name = "eks-admins"
# }


# resource "aws_iam_group_membership" "team" {
#   name = "eks-admin-group-membership"

#   users = [
#     aws_iam_user.user_one.name,
#     aws_iam_user.user_two.name,
#   ]

#   group = aws_iam_group.group.name
# }
