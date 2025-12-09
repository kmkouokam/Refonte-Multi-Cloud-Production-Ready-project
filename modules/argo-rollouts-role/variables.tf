variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
     default     = "multi-cloud-cluster"
}

variable "wait_for_k8s" {
  description = "Whether to wait for the Kubernetes cluster to be ready"
  type        = bool
  default     = true
}

 
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "argo_rollouts_role_name" {
description = "Name of the ClusterRole to create"
type = string
default = "argo-rollouts-role"
}

variable "eks_endpoint" {
  description = "The EKS cluster endpoint"
  type        = string
   
}

variable "eks_ca_certificate" {
  description = "The EKS cluster CA certificate"
  type        = string
 
}
