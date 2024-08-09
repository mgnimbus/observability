resource "helm_release" "external_dns" {
  name = "external-dns"

  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  create_namespace = true
  namespace        = var.dns_namespace

  set {
    name  = "image.repository"
    value = "registry.k8s.io/external-dns/external-dns"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.dns_service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.irsa_r53_role.arn
  }

  set {
    name  = "provider" # Default is aws (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
    value = "aws"
  }

  set {
    name  = "policy" # Default is "upsert-only" which means DNS records will not get deleted even equivalent Ingress resources are deleted (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
    value = "sync"   # "sync" will ensure that when ingress resource is deleted, equivalent DNS record in Route53 will get deleted
  }
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_ng_private]
}


## IAM Role ##

resource "aws_iam_policy" "irsa_r53_policy" {
  name        = "${local.name}-r53-policy"
  description = "To provide access to EKS to use AWS r53 services "

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "irsa_r53_role" {
  name = "${local.name}-r53-role-test"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.oidc_provider.arn}"
        }
        Condition = {
          StringEquals = {
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:aud" : "sts.amazonaws.com",
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:sub" : "system:serviceaccount:${var.dns_namespace}:${var.dns_service_account_name}"
          }
        }
      }
    ]
  })

  tags = {
    tag-key = "AllowExternalDNSUpdates"
  }
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_ng_private]
}



resource "aws_iam_role_policy_attachment" "EKSAmazonr53Role" {
  policy_arn = aws_iam_policy.irsa_r53_policy.arn
  role       = aws_iam_role.irsa_r53_role.name
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_ng_private]
}
