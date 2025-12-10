variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
     default     = "multi-cloud-cluster"
}

# variables.tf
variable "cloud_provider" {
  description = "The cloud provider to deploy to (aws or gcp)"
  type        = string
  default     = "aws"
  validation {
    condition     = contains(["aws", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be either 'aws' or 'gcp'"
  }
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

variable "is_aws" {
  type        = bool
  default     = false
}

variable "is_gcp" {
  description = "Whether to deploy GCP resources"
  type        = bool
  default     = false
}


variable "eks_dependency" {
  description = "Fake dependency to force ordering for EKS resources"
  type        = any
  default     = null
}

