variable "pubsub1" {
  type    = string
  default = "subnet-0202a0bded720d2c7"
}

variable "pubsub2" {
  type    = string
  default = "subnet-0567afbeed513173d"
}

variable "eksIAMRole" {
  type    = string
  default = "prodEKSCluster"
}

variable "EKSClusterName" {
  type    = string
  default = "prodEKS"
}

variable "k8sVersion" {
  type    = string
  default = "1.26"
}

variable "workerNodeIAM" {
  type    = string
  default = "prodWorkerNodes"
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
  default = "prod"
}