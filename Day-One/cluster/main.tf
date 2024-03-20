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

#call private_subnet data source
data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["ayodele-private*"]
  }
}

data "aws_security_group" "workernode" {
  name = "ayodele-lab-sg" # Name of the security group you want to retrieve
  # tags = {
  #   Name = "example-security-group"  # Optional: If your security group has a specific tag
  # }
}

# IAM Role for EKS to have access to the appropriate resources
resource "aws_iam_role" "controlplane-iam-role" {
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
  role       = aws_iam_role.controlplane-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.controlplane-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController-EKS" { #For pod security groups
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.controlplane-iam-role.name
}

## Create the EKS cluster
resource "aws_eks_cluster" "eks" {
  name     = "${var.owner}-${var.EKSClusterName}"
  role_arn = aws_iam_role.controlplane-iam-role.arn

  enabled_cluster_log_types = ["api", "audit", "scheduler", "controllerManager", "authenticator"]
  version                   = var.k8sVersion
  vpc_config {
    # You can set these as just private subnets if the Control Plane will be private
    subnet_ids = toset(data.aws_subnets.public.ids)
  }

  tags = merge({
    Name = "${var.owner}-${var.EKSClusterName}",
  Type = "Public" }, local.common_tags)

  depends_on = [
    aws_iam_role.controlplane-iam-role,
  ]
}

##### Cloudwatch log group for control plane logging
# resource "aws_cloudwatch_log_group" "eks_logs" {
#   # The log group name format is /aws/eks/<cluster-name>/cluster
#   # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
#   name              = "/aws/eks/${var.EKSClusterName}/cluster"
#   retention_in_days = 1

#   # ... potentially other configuration ...
# }

##### Worker Nodes
resource "aws_iam_role" "workernodes-iam-role" {
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
  role       = aws_iam_role.workernodes-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes-iam-role.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes-iam-role.name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy-eks" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.workernodes-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.workernodes-iam-role.name
}

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.owner}${var.environment}-Workernodes"
  node_role_arn   = aws_iam_role.workernodes-iam-role.arn
  subnet_ids      = toset(data.aws_subnets.public.ids)
  instance_types  = var.instanceType
  ami_type        = "AL2_x86_64"
  capacity_type   = var.node_capacity_type #'SPOT' is also a valid option for dev environments
  labels = {
    Environment = var.environment,
    Owner       = var.owner
  }

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  remote_access {
    ec2_ssh_key               = "ayodele-ansible-key"
    source_security_group_ids = [data.aws_security_group.workernode.id]
  }

  tags = merge({ Name = "${var.owner}${var.environment}-WorkerNodes" }, local.common_tags)

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  # Optional: Allow external changes like App Autoscaling without Terraform plan difference
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_eks_addon" "csi" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "aws-ebs-csi-driver"
  # addon_version = "v1.7.1"
  # For more information, see https://docs.aws.amazon.com/eks/latest/userguide/managing-add-ons.html
  # resolve_conflicts = "OVERWRITE"
  tags = local.common_tags
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "eks-pod-identity-agent"
  # addon_version = "v1.7.1"
  # For more information, see https://docs.aws.amazon.com/eks/latest/userguide/managing-add-ons.html
  # resolve_conflicts = "OVERWRITE"
  tags = local.common_tags
}