variable "vpn_name" {
  description = "Base name for resources"
  type        = string
}

# -------- GCP inputs --------
variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-east4"
}

variable "gcp_network_self_link" {
  description = "Self link of the GCP VPC to terminate the VPN on"
  type        = string
}

variable "gcp_router_asn" {
  description = "Private ASN for GCP Cloud Router (e.g., 65001)"
  type        = number

}

# -------- AWS inputs --------
variable "aws_region" {
  type    = string
  default = "us-east-1"

}
variable "aws_vpc_id" {
  type = string
}
# Route tables that should receive propagated routes from VGW
variable "aws_private_route_table_ids" {
  type = list(string)
}

# -------- Shared --------
variable "vpn_shared_secret" {
  description = "PSK used by both tunnels"
  type        = string
  sensitive   = true
  default = null

  validation {
    condition     = length(var.vpn_shared_secret) >= 8 && length(var.vpn_shared_secret) <= 64 && !startswith(var.vpn_shared_secret, "0")
    error_message = "vpn_shared_secret must be 8-64 chars and must not start with '0'."
  }
}

# Optional: set Amazon-side ASN(Autonomous System Number) for VGW (default 64512)
variable "aws_amazon_side_asn" {
  description = "value for Amazon-side ASN"
  type        = number

}

# Optional: advertise all subnets from GCP
variable "gcp_router_advertise_all_subnets" {
  type    = bool
  default = true
}

variable "vpn_name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "multi-cloud-vpn"
}

variable "aws_private_subnet_cidrs" {
  description = "List of private subnet CIDRs in AWS"
  type        = list(string)
}

variable "gcp_private_subnet_cidrs" {
  description = "List of private subnet CIDRs in GCP"
  type        = list(string)
}

variable "gke_master_cidr" {
  type    = string
  default = "172.16.0.0/28"
}
