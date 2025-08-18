variable "gcp_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-east1"
}
variable "availability_zone" {
  description = "The availability zone to deploy resources in"
  type        = string
  default     = "us-central1"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}
variable "cloud_provider" {
  description = "Cloud provider to use (aws or gcp)"
  type        = string
  default     = "gcp"
}
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "multi-cloud-vpc"
}

variable "gcp_project_id" {
  default = "prod-251618-359501"
}



variable "gcp_credentials_file" {
  default = "../../mygcp-creds.json"
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
  default     = "mydb"
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

# variable "vpc_security_group_ids" {
#   description = "Security group IDs or network for DB access"
#   type        = list(string)
#   default     = []
# }

variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}
