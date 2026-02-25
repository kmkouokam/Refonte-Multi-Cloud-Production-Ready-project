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

# output "gke_client_key" {
#   value = local.is_gcp ? google_container_cluster.gcp_cluster[0].master_auth[0].client_key : null
# }

output "gcp_service_account_email" {
  value       = length(google_service_account.gke_sa) > 0 ? google_service_account.gke_sa[0].email : null
  description = "The email of the GKE service account for IAM bindings"
}

output "gke_service_account_name" {
  value       = length(google_service_account.gke_sa) > 0 ? google_service_account.gke_sa[0].name : null
  description = "The full name of the GKE service account"
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

 


# output "cluster_name" {
#   value = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].name : (
#     local.is_gcp ? google_container_cluster.gcp_cluster[0].name : null
#   )
#   description = "Kubernetes cluster name (EKS if AWS, GKE if GCP)"
# }

output "aws_cluster_name" {
  value       = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].name : null
  description = "EKS cluster name (AWS only)"
}

output "gcp_cluster_name" {
  value       = local.is_gcp ? google_container_cluster.gcp_cluster[0].name : null
  description = "GKE cluster name (GCP only)"
}


# AWS EKS Node Role ARN
output "eks_node_role_arn" {
  value       = local.is_aws ? aws_iam_role.eks_node_role[0].arn : null
  description = "ARN of the EKS node IAM role (AWS only)"
}

output "aws_eks_cluster_id" {
  value       = local.is_aws ? aws_eks_cluster.aws_eks_cluster[0].id : null
  description = "ID of the EKS cluster (AWS only)"
}

# output "eks_oidc_provider_arn" {
#   description = "EKS OIDC provider ARN (AWS only)"
#   value       = local.is_aws ? aws_iam_openid_connect_provider.eks[0].arn : null
# }

# output "eks_oidc_provider_url" {
#   description = "EKS OIDC provider URL (AWS only)"
#   value       = local.is_aws ? aws_iam_openid_connect_provider.eks[0].url : null
# }

# output "alb_controller_irsa_role_arn" {
#   value = local.is_aws ? aws_iam_role.alb_controller_irsa[0].arn : null
# }


 
