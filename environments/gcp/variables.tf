variable "gcp_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-central1"
}

variable "availability_zones" {
  description = "List of availability zones for AWS"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gcp_subnetwork" {
  description = "Optional: existing GCP subnetwork name. If null, a new subnet will be created using CIDR blocks."
  type        = string
  default     = null
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (used only if creating new subnets)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (used only if creating new subnets)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}


variable "cloud_provider" {
  description = "Cloud provider to use (aws or gcp)"
  type        = string
  default     = "gcp"
}
variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "multi-cloud-vpc"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  default     = "prod-251618-359501"
}



variable "gcp_credentials_file" {
  description = "Path to the GCP credentials JSON file"
  default     = "../../mygcp-creds.json"
}

# variable "gcp_db_endpoint" {
#   type = string
# }

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

}


variable "kms_key_name" {
  description = "KMS key name for encryption"
  type        = string
  default     = "refonte-multicloud-kms-key"
}

variable "gcp_service_account_email" {
  description = "GCP service account email for IAM bindings"
  type        = string
  default     = "refonte-project@prod-251618-359501.iam.gserviceaccount.com"
}


variable "db_name" {
  description = "Database name"
  type        = string
  default     = "postgresdb"
}

variable "create_custom_db" {
  description = "Whether to create a custom database in addition to the default"
  type        = bool
  default     = true
}



variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_instance_class" {
  description = "Instance type / machine type"
  type        = string
  default     = "db-custom-1-3840" # GCP machine type
}

variable "db_storage_size" {
  description = "Database storage size in GB"
  type        = number
  default     = 20
}

variable "gcp_existing_private_ip_range" {
  description = "Existing allocated IP range for VPC peering"
  type        = string
  default     = "google-managed-services-multi-cloud-vpc"
}


variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"

}

variable "project" {
  description = "Project name"
  type        = string
  default     = "refonte-project"

}



variable "allowed_cidrs" {
  description = "List of CIDRs allowed for SSH/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ASN (Autonomous System Number) to use in Border Gateway Protocol (BGP)
variable "gcp_router_asn" {
  description = "GCP Cloud Router ASN"
  type        = number
  default     = 65001
}

variable "gcp_network_name" {
  description = "GCP VPC Network name (only for GCP)"
  type        = string
}

variable "private_subnet_ids" {
  description = "GCP Private Subnet IDs (only for GCP)"
  type        = list(string)
  default     = []
}

variable "gcp_web_fw_name" {
  description = "GCP Web Firewall Rule name"
  type        = string
}

variable "gcp_db_fw_name" {
  description = "GCP DB Firewall Rule name"
  type        = string
}


