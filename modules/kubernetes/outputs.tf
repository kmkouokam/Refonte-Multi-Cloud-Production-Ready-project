output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].endpoint : google_container_cluster.gcp_cluster[0].endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64)"
  value       = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].certificate_authority[0].data : google_container_cluster.gcp_cluster[0].master_auth[0].cluster_ca_certificate
}

output "cluster_name" {
  value = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].name : (
    local.is_gcp ? google_container_cluster.gcp_cluster[0].name : null
  )
  description = "Kubernetes cluster name (EKS if AWS, GKE if GCP)"
}

