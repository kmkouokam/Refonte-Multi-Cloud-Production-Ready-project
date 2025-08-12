# -------------------------------
# Outputs
# -------------------------------
output "cluster_name" {
  value = var.cluster_name
}

output "kubeconfig" {
  value = var.cloud_provider == "aws" ? aws_eks_cluster.aws_eks_cluster[0].endpoint : google_container_cluster.gcp_cluster[0].endpoint
}


