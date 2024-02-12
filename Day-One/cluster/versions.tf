terraform {
  backend "s3" {
    bucket = "ayodele-terraform-bucket"
    key    = "dev/eks-cluster.tfstate"
    region = "eu-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}