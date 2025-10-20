variable "aws_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-east-1"
}


variable "db_host" {
  type    = string
  default = null
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "us-central1"
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

variable "gcp_network_name" {
  description = "GCP VPC Network name (only for GCP)"
  type        = string
  default     = "multi-cloud-vpc"
}

# variable "gcp_private_subnet_names" {
#   description = "GCP private subnet names for private Cloud SQL network"
#   type        = list(string)
#   default     = [multi-cloud-private-0, multi-cloud-private-1]

# }


variable "gcp_web_fw_name" {
  description = "GCP Web Firewall Rule name"
  type        = string
  default     = "multi-cloud-web-fw"

}

variable "gcp_db_fw_name" {
  description = "GCP DB Firewall Rule name"
  type        = string
  default     = "multi-cloud-db-fw"

}
