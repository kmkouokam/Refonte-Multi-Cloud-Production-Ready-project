variable "aws_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
variable "gcp_region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "us-east1"
}
variable "gcp_credentials_file" {
  description = "Path to the GCP credentials file"
  type        = string
  default     = "./mygcp-creds.json"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "prod-251618-359501"
}


variable "vpn_name" {
  description = "Name of the resources"
  type        = string
  default     = "multi-cloud-vpn"
}

variable "vpn_shared_secret" {
  description = "Shared secret for the VPN connection"
  type        = string
  default     = null

}


