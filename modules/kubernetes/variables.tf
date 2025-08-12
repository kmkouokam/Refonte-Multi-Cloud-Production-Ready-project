# modules/k8s/variables.tf
variable "cloud_provider" {
  description = "Cloud provider to deploy to (aws|gcp)"
  type        = string
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "multi-cloud-cluster"
}


variable "gcp_network" {
  description = "GCP VPC network name"
  type        = string
  default     = null
}

variable "gcp_subnetwork" {
  description = "GCP subnetwork name"
  type        = string
  default     = null
}

variable "region" {
  description = "Region for cluster"
  type        = string
}

variable "project_id" {
  description = "GCP project ID (only for GCP)"
  type        = string
  default     = "prod-251618"
}


#shared variables
variable "public_subnet_ids" {
  description = "AWS public subnet IDs for EKS"
  type        = list(string)
  default     = []
}
