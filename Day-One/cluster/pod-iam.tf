data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}


resource "aws_iam_role" "example" {
  name               = "ayodele-pod-iam-demo"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
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

resource "aws_eks_pod_identity_association" "association" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "default"
  service_account = "movie-sa"
  role_arn        = aws_iam_role.example.arn
}