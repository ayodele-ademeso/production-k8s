variable "eksIAMRole" {
  type    = string
  default = "devEKSCluster-role"
}

variable "EKSClusterName" {
  type    = string
  default = "devEKS"
}

variable "k8sVersion" {
  type    = string
  default = "1.28"
}

variable "workerNodeIAM" {
  type    = string
  default = "devWorkerNodes-role"
}

variable "max_size" {
  type    = string
  default = 3
}

variable "desired_size" {
  type    = string
  default = 2
}

variable "min_size" {
  type    = string
  default = 2
}

variable "instanceType" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  description = "Owner of the resources created, used in resource names and tags"
  type        = string
  default     = "ayodele"
}

variable "node_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "max_unavailable_percentage" {
  type    = number
  default = 50
}