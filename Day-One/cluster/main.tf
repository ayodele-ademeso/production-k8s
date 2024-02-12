locals {
  common_tags = {
    "Environment" = "${var.environment}"
    "Managed By"  = "Terraform",
    "Owned By"    = "Ayodele-UK"
  }
}

#call public_subnet data source
data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["ayodele-public*"]
  }
}

# IAM Role for EKS to have access to the appropriate resources
resource "aws_iam_role" "eks-iam-role" {
  name = "${var.owner}-${var.eksIAMRole}"

  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

## Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}

## Create the EKS cluster
resource "aws_eks_cluster" "eks" {
  name     = "${var.owner}-${var.EKSClusterName}"
  role_arn = aws_iam_role.eks-iam-role.arn

  enabled_cluster_log_types = ["api", "audit", "scheduler", "controllerManager"]
  version                   = var.k8sVersion
  vpc_config {
    # You can set these as just private subnets if the Control Plane will be private
    subnet_ids = toset(data.aws_subnets.public.ids)
  }

  tags = merge({
    Name = "${var.owner}-${var.EKSClusterName}",
  Type = "Public" }, local.common_tags)

  depends_on = [
    aws_iam_role.eks-iam-role,
  ]
}

## Worker Nodes
resource "aws_iam_role" "workernodes" {
  name = "${var.owner}-${var.workerNodeIAM}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy-eks" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.owner}${var.environment}-Workernodes"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = toset(data.aws_subnets.public.ids)
  instance_types  = var.instanceType
  ami_type        = "AL2_x86_64"
  capacity_type   = "ON_DEMAND"
  labels = {
    Environment = var.environment,
    Owner       = var.owner
  }

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  tags = merge({ Name = "${var.owner}${var.environment}-WorkerNodes" }, local.common_tags)

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  ]
}

resource "aws_eks_addon" "csi" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "aws-ebs-csi-driver"
  # addon_version = "v1.7.1"
  # For more information, see https://docs.aws.amazon.com/eks/latest/userguide/managing-add-ons.html
  resolve_conflicts = "OVERWRITE"
  tags              = local.common_tags
}