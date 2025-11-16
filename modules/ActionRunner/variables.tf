variable "vpc_id" {
  description = "The VPC ID where the GitHub Actions runner will be deployed"
  type        = string
}

variable "ssh_key" {
  description = "The SSH key name to access the GitHub Actions runner EC2 instance"
  type        = string
  default = "virg.keypair"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-1"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "multi-cloud-cluster"
}    

