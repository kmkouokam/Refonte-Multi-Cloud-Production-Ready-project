variable "cloud_provider" {
  description = "Cloud provider to use: aws or gcp"
  type        = string
}

variable "vpc_cidr" {
  description = "value for the VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "multi-cloud"
}

# AWS specific
variable "availability_zones" {
  description = "List of availability zones for AWS"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# GCP specific
variable "gcp_region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-east1"
}

# Shared
variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}


