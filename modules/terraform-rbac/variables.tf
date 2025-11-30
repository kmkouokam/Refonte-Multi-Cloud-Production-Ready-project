variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "github_runner_role_arn" {
  description = "IAM Role ARN to attach to the GitHub Action Runner EC2 instance"
  type        = string
}

variable "extra_role_arns" {
  description = "List of extra IAM Role ARNs to attach to the GitHub Action Runner EC2 instance"
  type        = list(string)
  default     = []
}

variable "eks_node_role_arn" {
  description = "EKS node IAM role ARN"
  type        = string
}

variable "wait_for_k8s" {
  description = "A dummy dependency to force RBAC to wait for EKS"
  type        = any
  default     = null
}



