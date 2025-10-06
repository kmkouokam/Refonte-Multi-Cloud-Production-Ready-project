# -------------------------
# GCP outputs
# -------------------------
output "gke_endpoint" {
  description = "GKE cluster endpoint (GCP only)"
  value       = local.is_gcp ? google_container_cluster.gcp_cluster[0].endpoint : null
}

output "gke_ca_certificate" {
  description = "GKE cluster CA certificate (base64)"
  value       = local.is_gcp ? google_container_cluster.gcp_cluster[0].master_auth[0].cluster_ca_certificate : null
}

# -------------------------
# AWS outputs
# -------------------------
output "eks_endpoint" {
  description = "EKS cluster endpoint (AWS only)"
  value       = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].endpoint : null
}

output "eks_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  value       = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].certificate_authority[0].data : null
}


output "cluster_name" {
  value = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].name : (
    local.is_gcp ? google_container_cluster.gcp_cluster[0].name : null
  )
  description = "Kubernetes cluster name (EKS if AWS, GKE if GCP)"
}

# AWS EKS Node Role ARN
output "node_role_arn" {
  value       = local.is_aws ? aws_iam_role.eks_node_role[0].arn : null
  description = "ARN of the EKS node IAM role (AWS only)"
}

