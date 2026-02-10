variable "aws_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "github_runner_role_arn" {
  description = "The ARN of the IAM role for the GitHub Actions runner."
  type        = string
  default = null
  
}

variable "eks_node_role_arn" {
  description = "The ARN of the IAM role for the EKS node group."
  type        = string
  default     = null
}


variable "db_host" {
  type    = string
  default = null
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "us-east4"
}
variable "gcp_credentials_file" {
  description = "Path to the GCP credentials file"
  type        = string
  default     = "./mygcp-creds.json"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "prod-251618-359501"
}


variable "vpn_name" {
  description = "Name of the resources"
  type        = string
  default     = "multi-cloud-vpn"
}

variable "vpn_shared_secret" {
  description = "Shared secret for the VPN connection"
  type        = string
  default     = null

}

variable "aws_cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "multi-cloud-cluster"
}

variable "gcp_cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "multi-cloud-cluster"
  
}

variable "cloud_provider" {
  description = "Cloud provider to use (aws or gcp)"
  type        = string
  default     = "gcp"
}

variable "gcp_network_name" {
  description = "GCP VPC Network name (only for GCP)"
  type        = string
  default     = "multi-cloud-vpc"
}

# variable "gcp_private_subnet_names" {
#   description = "GCP private subnet names for private Cloud SQL network"
#   type        = list(string)
#   default     = [multi-cloud-private-0, multi-cloud-private-1]

# }


variable "gcp_web_fw_name" {
  description = "GCP Web Firewall Rule name"
  type        = string
  default     = "multi-cloud-web-fw"

}

variable "gcp_db_fw_name" {
  description = "GCP DB Firewall Rule name"
  type        = string
  default     = "multi-cloud-db-fw"

}
