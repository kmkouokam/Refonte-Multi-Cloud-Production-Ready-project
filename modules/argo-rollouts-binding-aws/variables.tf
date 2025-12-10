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
  description = "Kubernetes cluster name"
  type        = string
  default     = "multi-cloud-cluster"
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

variable "github_runner_role_name" {
  description = "Name of the GitHub Action Runner IAM Role"
  type        = string
 
  
}

variable "service_account_namespace" {
  default = "default"
     type    = string
}
 

variable "argo_rollouts_role_name" {
  type = string
}

 

variable "map_user_arn" {
type = string
default = "arn:aws:iam::435329769674:user/refonte"
}

variable "eks_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "eks_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
}


variable "eks_dependency" {
  description = "Fake dependency to force ordering"
  type        = any
  default     = null
}

variable "is_aws" {
  description = "Whether the deployment is on AWS"
  type        = bool
  default     = true
}

