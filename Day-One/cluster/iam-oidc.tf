data "tls_certificate" "cluster_certificate" {
  url = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster_identity_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_certificate.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}

resource "aws_iam_role" "eks_pods_ddb_s3_only_role" {
  name = "ayodele-eks-pods-ddb-s3-only-role"

  assume_role_policy = templatefile("AssumeRolePolicy.json", {
    OIDC_ARN        = aws_iam_openid_connect_provider.eks_cluster_identity_provider.arn,
    OIDC_ID         = replace(aws_eks_cluster.eks.identity.0.oidc.0.issuer, "https://", "")
    NAMESPACE       = "default",
    SERVICE_ACCOUNT = "movies-sa"
  })
  inline_policy {
    name = "inline_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "dynamodb:*",
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
        },
      ]
    })
  }
}

# resource "aws_iam_role_policy_attachment" "eks_AmazonDynamoDBReadOnlyAccess" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
#   role       = aws_iam_role.eks_pods_ddb_s3_only_role.name
# }