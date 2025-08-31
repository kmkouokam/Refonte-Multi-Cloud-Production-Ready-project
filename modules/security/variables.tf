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


variable "kms_key_name" {
  description = "KMS key name for encryption"
  type        = string

}

variable "cloud_provider" {
  description = "The cloud provider to use (aws or gcp)"
  type        = string

}

variable "name_suffix" {
  description = "Random suffix for resource names"
  type        = string

}

# GCP specific
variable "gcp_region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-central1"

}

variable "project" {
  description = "Project or environment name"
  type        = string

}


variable "secret_name" {
  type        = string
  description = "Name of the secret"

}


variable "gcp_project_id" {
  description = "GCP project ID (only for GCP)"
  type        = string
  default     = null
}




