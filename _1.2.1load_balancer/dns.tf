resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = var.dns_namespace
  }
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = var.dns_service_account_name
    namespace = kubernetes_namespace.external_dns.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn"     = aws_iam_role.irsa_r53_role.arn,
      "meta.helm.sh/release-namespace" = kubernetes_namespace.external_dns.metadata[0].name
      "meta.helm.sh/release-name"      = "external-dns"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }
}
resource "helm_release" "external_dns" {
  name = "external-dns"

  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  create_namespace = false
  namespace        = kubernetes_namespace.external_dns.metadata[0].name

  values = [
    templatefile("${path.module}/manifests/dns.yaml", {
      region = var.aws_region
      }
  )]
  depends_on = [kubernetes_service_account.external_dns, module.private_zones]
}

# k create ns external-dns
# kubectl create serviceaccount "external-dns" --namespace external-dns

# kubectl patch serviceaccount "external-dns" --namespace external-dns --patch \
#  "{\"metadata\": { \"annotations\": { \"eks.amazonaws.com/role-arn\": \"arn:aws:iam::058264194719:role/meda-dev-mantis-r53-role-test\" }}}"
# # helm upgrade --install external-dns external-dns/external-dns --values dns.yaml
# kubectl label serviceaccount external-dns app.kubernetes.io/managed-by=Helm --namespace external-dns
# kubectl annotate serviceaccount external-dns meta.helm.sh/release-name=external-dns --namespace external-dns
# kubectl annotate serviceaccount external-dns meta.helm.sh/release-namespace=external-dns --namespace external-dns


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
          Federated = "${data.terraform_remote_state.eks.outputs.oidc_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:aud" : "sts.amazonaws.com",
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub" : "system:serviceaccount:${var.dns_namespace}:${var.dns_service_account_name}"
          }
        }
      }
    ]
  })

  tags = {
    tag-key = "AllowExternalDNSUpdates"
  }
}



resource "aws_iam_role_policy_attachment" "EKSAmazonr53Role" {
  policy_arn = aws_iam_policy.irsa_r53_policy.arn
  role       = aws_iam_role.irsa_r53_role.name
}
