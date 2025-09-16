

output "gcp_vpc_self_link" {
  value = module.vpc.gcp_vpc_self_link
}

output "gcp_private_subnet_cidrs" {
  value = module.vpc.gcp_private_subnet_cidrs
}

output "gcp_public_subnet_cidrs" {
  value = module.vpc.gcp_public_subnet_cidrs
}

output "gcp_db_endpoint" {
  value = module.gcp_env.db_endpoint
}

# environments/gcp/outputs.tf
output "gke_cluster_endpoint" {
  value = module.k8s.cluster_endpoint
}

output "gke_cluster_ca_certificate" {
  value = module.k8s.cluster_ca_certificate
}


