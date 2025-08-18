variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"

}

variable "aws_iam_roles" {
  description = "List of IAM roles to create in AWS"
  type        = list(string)
  default     = []
}

variable "gcp_iam_bindings" {
  description = "Map of GCP IAM bindings {role => members}"
  type        = map(list(string))
  default     = {}
}

variable "allowed_cidrs" {
  description = "List of CIDRs allowed for SSH/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kms_key_name" {
  description = "KMS key name for encryption"
  type        = string
  default     = "refonte-multicloud-kms-key"
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

variable "vpc_name" {
  description = "GCP VPC network name to attach resources to"
  type        = string
  default     = "multi-cloud-vpc"
}

# GCP specific
variable "gcp_region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-east1"
}

variable "aws_kms_alias" {
  description = "KMS key alias for encryption"
  type        = string
  default     = "alias/refonte-multicloud-kms-key"
}

variable "project" {
  description = "Project or environment name"
  type        = string
  default     = "refonte-project"
}


variable "secret_name" {
  type        = string
  description = "Name of the secret"
  default     = "/production/mysql/creds"
}
