###############################################
# Read Cluster
###############################################

# data "aws_eks_cluster" "eks" {
#   name       = var.cluster_name
#   depends_on = [var.wait_for_k8s]
# }

locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}



# Wait for EKS endpoint
resource "null_resource" "wait_for_eks" {
  provisioner "local-exec" {
    command = "echo 'Waiting for EKS endpoint...' && sleep 30"
  }
  depends_on = [var.wait_for_k8s]
}

# ----------------------------------------
# Kubernetes bootstrap provider to patch aws-auth
# ----------------------------------------
provider "kubernetes" {
  alias                  = "bootstrap"
  host                   = var.eks_endpoint != null ? var.eks_endpoint : ""
  cluster_ca_certificate = (
    var.eks_ca_certificate != null
    ? base64decode(var.eks_ca_certificate)
    : ""
  )
  # token                  = data.aws_eks_cluster_auth.eks.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.aws_region
    ]
  }

}




#------------------------------
# Shared Cluster Role for Argo Rollouts
#------------------------------
 



resource "kubernetes_cluster_role" "argo_rollouts" {
  count = var.is_aws || var.is_gcp ? 1 : 0
  provider = kubernetes.bootstrap
  metadata {
    name = var.argo_rollouts_role_name
  }


  rule {
    api_groups = [""]
    resources  = ["configmaps", "services", "endpoints", "pods", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["rollouts"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}
