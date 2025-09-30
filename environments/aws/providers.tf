# AWS EKS auth
data "aws_eks_cluster_auth" "eks" {
  name       = module.k8s[0].cluster_name
  depends_on = [module.k8s]
}



provider "kubernetes" {
  alias                  = "aws"
  host                   = module.k8s[0].cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s[0].cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.eks.token



}

# provider "helm" {
#   alias      = "aws"
#   kubernetes = kubernetes.aws
# }

# AWS Provider
provider "aws" {
  region = var.aws_region
}


# ----------------
# Helm Provider (AWS)
# ----------------
provider "helm" {
  alias = "aws"
  kubernetes {
    host                   = module.k8s[0].cluster_endpoint
    cluster_ca_certificate = base64decode(module.k8s[0].cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.eks.token
  }

}
