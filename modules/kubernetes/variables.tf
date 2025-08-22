# modules/k8s/variables.tf
variable "cloud_provider" {
  description = "Cloud provider to deploy to (aws|gcp)"
  type        = string
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string

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


#shared variables
variable "public_subnet_ids" {
  description = "AWS public subnet IDs for EKS"
  type        = list(string)
  default     = []
}

variable "gcp_project_id" {
  description = "GCP project ID (only for GCP)"
  type        = string

}

variable "vpc_name" {
  description = "GCP VPC name (only for GCP)"
  type        = string

}

variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}
