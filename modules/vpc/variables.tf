variable "cloud_provider" {
  description = "Cloud provider to use: aws or gcp"
  type        = string
}

variable "vpc_cidr" {
  description = "value for the VPC CIDR block"
  type        = string

}

variable "vpc_name" {
  description = "Prefix for resource names"
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


