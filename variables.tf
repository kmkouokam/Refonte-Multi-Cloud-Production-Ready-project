variable "aws_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
variable "gcp_region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "us-west1-a"
}
variable "gcp_credentials_file" {
  description = "Path to the GCP credentials file"
  type        = string
  default     = "./mygcp-creds.json"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "prod-251618"
}

variable "cloud_provider" {
  description = "Cloud provider to use (aws or gcp)"
  type        = string
  default     = "aws"
}
