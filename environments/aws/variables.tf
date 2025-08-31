variable "aws_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "cloud_provider" {
  description = "The cloud provider to use (aws or gcp)"
  type        = string
  default     = "aws"
}

variable "availability_zones" {
  description = "List of availability zones for AWS"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "multi-cloud-vpc"
}

variable "public_subnet_cidrs" {
  description = "The CIDR block for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR block for the private subnet"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "kms_key_name" {
  description = "KMS key alias for encryption"
  type        = string
  default     = "alias/refonte-multicloud-kms-key"
}


variable "db_name" {
  description = "Database name"
  type        = string
  default     = "postgresdb"
}



variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_instance_class" {
  description = "Instance type / machine type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_storage_size" {
  description = "Database storage size in GB"
  type        = number
  default     = 20
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

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "multi-cloud-cluster"
}

# ASN (Autonomous System Number) to use in Border Gateway Protocol (BGP)
variable "aws_amazon_side_asn" {
  type    = number
  default = 64512
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  default     = "prod-251618-359501"
}

variable "gcp_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-central1"
}


variable "create_custom_db" {
  description = "Whether to create a custom database in addition to the default"
  type        = bool
  default     = true
}

variable "gcp_vpc_self_link" {
  description = "Self link of the GCP VPC network"
  type        = string
}

