# ----------------
# EKS Authentication
# ----------------
data "aws_eks_cluster_auth" "eks" {
  name       = module.k8s[0].cluster_name
  depends_on = [module.k8s]
}

# ----------------
# Kubernetes Provider (AWS EKS)
# ----------------
provider "kubernetes" {
  alias                  = "aws"
  host                   = module.k8s[0].eks_endpoint
  cluster_ca_certificate = base64decode(module.k8s[0].eks_ca_certificate)
  # token                  = data.aws_eks_cluster_auth.eks.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name,
      "--region", var.aws_region
    ]
    env = {
      AWS_PROFILE = ""
    }
  }  
}

# ----------------
# AWS Provider
# ----------------
provider "aws" {
  region = var.aws_region
}

# ----------------
# Helm Provider (AWS EKS)
# ----------------
provider "helm" {
  alias = "aws"
  kubernetes = {
    host                   = module.k8s[0].eks_endpoint
    cluster_ca_certificate = base64decode(module.k8s[0].eks_ca_certificate)
    # token                  = data.aws_eks_cluster_auth.eks.token
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name
      
        , "--region", var.aws_region
      ]
    }
  }
}

 
