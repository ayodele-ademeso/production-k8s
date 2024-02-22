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
  default = "1.27"
}

variable "workerNodeIAM" {
  type    = string
  default = "devWorkerNodes-role"
}

variable "max_size" {
  type    = string
  default = 2
}

variable "desired_size" {
  type    = string
  default = 1
}
variable "min_size" {
  type    = string
  default = 1
}

variable "instanceType" {
  type    = list(any)
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