data "google_client_config" "default" {}

provider "kubernetes" {
  alias                  = "gcp"
  host                   = "https://${module.k8s[0].cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.k8s[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

# provider "helm" {
#   alias      = "gcp"
#   kubernetes = kubernetes.gcp

# }


# Google provider
provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = file("${path.module}/${var.gcp_credentials_file}")
}


provider "helm" {
  alias = "gcp"
  kubernetes {
    host                   = "https://${module.k8s[0].cluster_endpoint}"
    cluster_ca_certificate = base64decode(module.k8s[0].cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
