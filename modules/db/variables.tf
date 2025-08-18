variable "cloud_provider" {
  description = "Cloud provider: aws or gcp"
  type        = string
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
  default     = "t3.micr"
}

variable "db_storage_size" {
  description = "Database storage size in GB"
  type        = number
  default     = 20
}

variable "vpc_security_group_ids" {
  description = "Security group IDs or network for DB access"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "Cloud region"
  type        = string
}

variable "db_password" {
  description = "Database password (from security module)"
  type        = string
}

variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}

variable "gcp_project_id" {
  description = "GCP project ID (only for GCP)"
  type        = string
  default     = "prod-251618-359501"
}

variable "vpc_name" {
  description = "value for GCP VPC name (only for GCP)"
  default     = "multi-cloud-vpc"
}

variable "create_custom_db" {
  description = "Whether to create a custom database in addition to the default"
  type        = bool
  default     = true
}

variable "db_subnet_ids" {
  description = "List of private subnet IDs for DB instances"
  type        = list(string)
  default     = []
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "prod"

}
