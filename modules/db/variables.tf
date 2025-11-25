variable "cloud_provider" {
  description = "Cloud provider: aws or gcp"
  type        = string
}

variable "aws_vpc_id" {
  description = "AWS VPC ID (only for AWS)"
  type        = string
}

variable "aws_web_sg_id" {
  description = "AWS Web SG ID (only for AWS)"
  type        = string
}

variable "aws_db_sg_id" {
  description = "AWS DB SG ID (only for AWS)"
  type        = string
}



variable "db_name" {
  description = "Database name"
  type        = string

}

variable "db_username" {
  description = "Database username"
  type        = string

}

variable "db_password" {
  description = "Database password"
  type        = string

}

variable "db_instance_class" {
  description = "Instance type / machine type"
  type        = string
  default     = "db.t3.micro" # AWS instance type / GCP machine type
}

variable "db_storage_size" {
  description = "Database storage size in GB"
  type        = number

}

variable "name_suffix" {
  description = "Random suffix for resource names"
  type        = string
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

variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}

variable "gcp_project_id" {
  description = "GCP project ID (only for GCP)"
  type        = string

}

variable "gcp_network_name" {
  description = "GCP VPC Network name (only for GCP)"
  type        = string
}

variable "gcp_subnet_name" {
  description = "GCP Subnet name (only for GCP)"
  type        = string

}

variable "gcp_web_fw_name" {
  description = "GCP Web Firewall Rule name"
  type        = string

}

variable "gcp_db_fw_name" {
  description = "GCP DB Firewall Rule name"
  type        = string

}

variable "create_custom_db" {
  description = "Whether to create a custom database in addition to the default"
  type        = bool

}

variable "db_subnet_ids" {
  description = "List of private subnet IDs for DB instances"
  type        = list(string)
  default     = []
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string


}


