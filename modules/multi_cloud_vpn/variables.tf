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
  default = "us-central1"
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

