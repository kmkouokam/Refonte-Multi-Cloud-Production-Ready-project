variable "cloud_provider" {
  description = "Cloud provider to use: aws or gcp"
  type        = string
}

variable "vpc_cidr" {
  description = "value for the VPC CIDR block"
  type        = string

}

variable "name_prefix" {
  description = "Prefix for naming VPC resources"
  type        = string
}


# AWS specific
variable "availability_zones" {
  description = "List of availability zones for AWS"
  type        = list(string)

}

# GCP specific
variable "gcp_region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-east4"

}

variable "enabled_apis" {
  description = "List of GCP APIs to enable before provisioning"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string

}

# Shared
variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)

}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)

}

variable "gcp_vpc_self_link" {
  description = "GCP VPC self_link for private Cloud SQL network"
  type        = string
  default     = null
}

variable "manage_default_routes" {
  description = "Whether to manage and clean up default routes created by GCP"
  type        = bool
  default     = false
}


variable "env" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

