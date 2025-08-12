output "vpc_id" {
  value = var.cloud_provider == "aws" ? aws_vpc.main[0].id : google_compute_network.main[0].id
}

output "public_subnet_ids" {
  value = var.cloud_provider == "aws" ? aws_subnet.public[*].id : google_compute_subnetwork.public[*].id
}

output "private_subnet_ids" {
  value = var.cloud_provider == "aws" ? aws_subnet.private[*].id : google_compute_subnetwork.private[*].id
}


