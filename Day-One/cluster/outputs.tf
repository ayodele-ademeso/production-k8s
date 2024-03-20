output "cluster_name" {
  description = "The name of the created cluster"
  value       = aws_eks_cluster.eks
}

output "cluster_certificate_authority_data" {
  description = "Nested Attribute containing certificate authority data for created cluster. This is base64 encoded"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_version" {
  description = "value of eks.version in the AWS provider"
  value       = aws_eks_cluster.eks.version
}

output "cluster_oidc_issuer_url" {
  description = "The URL of the EKS cluster OIDC issuer"
  value       = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

##### Worker Node Outputs
output "worker_node_group_id" {
  description = "Worker node group ID"
  value       = aws_eks_node_group.worker-node-group.*.id
}