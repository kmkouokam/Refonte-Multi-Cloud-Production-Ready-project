# modules/k8s/variables.tf
variable "cloud_provider" {
  description = "Cloud provider to deploy to (aws|gcp)"
  type        = string
}

variable "aws_cluster_name" {
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

variable "aws_region" {
  description = "Region for AWS resources"
  type        = string
  default     = "us-east-1"
}

variable "gcp_region" {
  description = "Region for GCP resources"
  type        = string
  default     = "us-east4"
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
  default     = null
}



variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}

variable "extra_role_arns" {
  type = list(string) 
  default = [] 
} 


variable "gcp_node_locations" {
  description = "GKE node zones within the region (exclude stockout zones)"
  type        = list(string)
  default     = ["us-east4-b", "us-east4-a"]
}
