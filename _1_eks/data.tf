# AWS Availability Zones Datasource
data "aws_availability_zones" "available" {
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_iam_policy" "vpc_cni_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# data "aws_iam_policy" "efs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
# }
