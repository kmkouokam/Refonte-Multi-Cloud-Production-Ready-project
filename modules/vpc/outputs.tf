output "vpc_id" {
  value = var.cloud_provider == "aws" ? aws_vpc.main[0].id : google_compute_network.main[0].id
}

output "public_subnet_ids" {
  value = var.cloud_provider == "aws" ? aws_subnet.public[*].id : google_compute_subnetwork.public[*].id
}

output "private_subnet_ids" {
  value = var.cloud_provider == "aws" ? aws_subnet.private[*].id : google_compute_subnetwork.private[*].id
}

output "gcp_vpc_self_link" {
  description = "Self link of the GCP VPC (used for private service networking)"
  value       = length(google_compute_network.main) > 0 ? google_compute_network.main[0].self_link : null
}




