

output "gcp_vpc_self_link" {
  value = module.vpc[0].gcp_vpc_self_link
}

output "gcp_private_subnet_cidrs" {
  value = module.vpc[0].gcp_private_subnet_cidrs
}

output "gcp_public_subnet_cidrs" {
  value = module.vpc[0].gcp_public_subnet_cidrs
}

output "gcp_db_endpoint" {
  value = module.gcp_db[0].db_endpoint
}

# environments/gcp/outputs.tf
output "gke_cluster_endpoint" {
  value = module.k8s[0].cluster_endpoint
}

output "gke_cluster_ca_certificate" {
  value = module.k8s[0].cluster_ca_certificate
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


# -------------------------
# GCP Helm Outputs
# -------------------------

output "flask_app_release_name_gcp" {
  value       = helm_release.flask_app_gcp[0].name
  description = "Helm release name for the Flask app on GCP"
}

output "flask_app_namespace_gcp" {
  value       = helm_release.flask_app_gcp[0].namespace
  description = "Kubernetes namespace for the Flask app on GCP"
}

output "flask_app_status_gcp" {
  value       = helm_release.flask_app_gcp[0].status
  description = "Status of the Flask app Helm release on GCP"
}

# Flask App Service Ingress IP (GCP GKE)
output "flask_app_url_gcp" {
  description = "Public URL of the Flask app on GCP"
  value       = "http://${data.kubernetes_service.flask_app_gcp.status[0].load_balancer[0].ingress[0].ip}"
}

# output "flask_app_release_name_gcp" {
#   value = length(helm_release.flask_app) > 0 ? helm_release.flask_app[0].name : null
# }

# output "flask_app_namespace_gcp" {
#   value = length(helm_release.flask_app) > 0 ? helm_release.flask_app[0].namespace : null
# }


