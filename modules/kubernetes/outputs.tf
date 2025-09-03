# -------------------------------
# Outputs
# -------------------------------
output "cluster_name" {
  value = var.cluster_name
}

output "kubeconfig" {
  value = var.cloud_provider == "aws" ? aws_eks_cluster.aws_eks_cluster[0].endpoint : google_container_cluster.gcp_cluster[0].endpoint
}


# output "enabled_apis" {
#   description = "List of enabled APIs"
#   value       = keys(google_project_service.secret_manager)
# }

