
# AWS outputs
output "aws_vpc_id" {
  value       = var.cloud_provider == "aws" ? aws_vpc.main[0].id : null
  description = "AWS VPC ID (only for AWS)"
}

output "aws_web_sg_id" {
  value       = var.cloud_provider == "aws" ? aws_security_group.web_sg[0].id : null
  description = "AWS Web SG ID (only for AWS)"
}

output "aws_db_sg_id" {
  value       = var.cloud_provider == "aws" ? aws_security_group.db_sg[0].id : null
  description = "AWS DB SG ID (only for AWS)"
}

# GCP outputs
output "gcp_network_name" {
  value       = var.cloud_provider == "gcp" ? google_compute_network.vpc_network[0].name : null
  description = "GCP VPC Network name (only for GCP)"
}



output "gcp_web_fw_name" {
  value       = var.cloud_provider == "gcp" ? google_compute_firewall.web_fw[0].name : null
  description = "GCP Web Firewall Rule name"
}

output "gcp_db_fw_name" {
  value       = var.cloud_provider == "gcp" ? google_compute_firewall.db_fw[0].name : null
  description = "GCP DB Firewall Rule name"
}

# AWS outputs
output "aws_public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "AWS public subnet IDs"
}

output "aws_private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "AWS private subnet IDs"
}

# GCP outputs
output "gcp_public_subnet_name" {
  value = length(google_compute_subnetwork.public) > 0 ? google_compute_subnetwork.public[0].name : null
}

output "gcp_private_subnet_name" {
  value = length(google_compute_subnetwork.private) > 0 ? google_compute_subnetwork.private[0].name : null
}


output "enabled_services" {
  value = [
    for s in google_project_service.enabled_apis : s.id
  ]
}

output "gcp_vpc_self_link" {
  description = "Self link of the GCP VPC (used for private service networking)"
  value       = length(google_compute_network.vpc_network) > 0 ? google_compute_network.vpc_network[0].self_link : null
}


output "private_route_table_ids" {
  value = var.cloud_provider == "aws" ? aws_route_table.private[*].id : null
}


# AWS subnet CIDRs
output "aws_public_subnet_cidrs" {
  description = "CIDR blocks for AWS public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "aws_private_subnet_cidrs" {
  description = "CIDR blocks for AWS private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# GCP subnet CIDRs
output "gcp_public_subnet_cidrs" {
  description = "CIDR ranges for GCP public subnets"
  value       = [for s in google_compute_subnetwork.public : s.ip_cidr_range]
}

output "gcp_private_subnet_cidrs" {
  description = "CIDR ranges for GCP private subnets"
  value       = [for s in google_compute_subnetwork.private : s.ip_cidr_range]
}






