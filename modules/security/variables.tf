variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string


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

}

variable "kms_key_name" {
  description = "KMS key name for encryption"
  type        = string

}


variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string

}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
  default     = ""
}

variable "cloud_provider" {
  description = "The cloud provider to use (aws or gcp)"
  type        = string

}

variable "vpc_name" {
  description = "GCP VPC network name to attach resources to"
  type        = string

}

# GCP specific
variable "gcp_region" {
  description = "GCP region to deploy resources"
  type        = string

}



variable "project" {
  description = "Project or environment name"
  type        = string

}


variable "secret_name" {
  type        = string
  description = "Name of the secret"

}
