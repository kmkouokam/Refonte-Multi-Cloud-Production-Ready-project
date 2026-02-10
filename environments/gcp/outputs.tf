output "gcp_cluster_name" {
  value = module.k8s[0].gcp_cluster_name
}

output "gcp_vpc_self_link" {
  value = module.vpc[0].gcp_vpc_self_link
}

output "gcp_private_subnet_cidrs" {
  value = module.vpc[0].gcp_private_subnet_cidrs
}

output "gcp_public_subnet_cidrs" {
  value = module.vpc[0].gcp_public_subnet_cidrs
}

output "gcp_db_host" {
  value = module.gcp_db[0].db_endpoint
}

output "gcp_db_name" {
  value = module.gcp_db[0].db_name
}

output "gcp_db_username" {
  value = module.gcp_db[0].db_username
}


output "gcp_db_password" {
  value       = local.is_gcp ? module.gcp_security[0].gcp_db_password : null
  description = "GCP DB password for Helm"
  sensitive   = true
}

# environments/gcp/outputs.tf
output "gke_cluster_endpoint" {
  value = module.k8s[0].gke_endpoint
}

output "gke_cluster_ca_certificate" {
  value = module.k8s[0].gke_ca_certificate
}

output "gcp_db_fw_name" {
  value = module.vpc[0].gcp_db_fw_name
}

output "gcp_network_name" {
  value = module.vpc[0].gcp_network_name
}

output "gcp_subnet_name" {
  value = module.vpc[0].gcp_private_subnet_name
}

output "gcp_web_fw_name" {
  value = module.vpc[0].gcp_web_fw_name
}

output "db_endpoint" {
  value = module.gcp_db[0].db_endpoint
}


output "gcp_service_account_email" {
  value = length(module.k8s) > 0 ? module.k8s[0].gcp_service_account_email : null
}

output "gke_service_account_name" {
  value = length(module.k8s) > 0 ? module.k8s[0].gke_service_account_name : null
}
 