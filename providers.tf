terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.12.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
  }
}

# ----------------
# Random provider
# ----------------
provider "random" {}

# ----------------
# AWS Providers
# ----------------
provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "aws"
  region = var.aws_region
}

# ----------------
# AWS EKS Kubernetes provider
# ----------------
data "aws_eks_cluster_auth" "eks" {
  name = module.aws_env.module.k8s.cluster_name
}

provider "kubernetes" {
  alias                  = "aws"
  host                   = module.aws_env.module.k8s.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aws_env.module.k8s.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  alias      = "aws"
  kubernetes = kubernetes.aws
}

# ----------------
# GCP Providers
# ----------------
provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = file("${path.module}/${var.gcp_credentials_file}")
}

provider "google" {
  alias       = "gcp"
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = file("${path.module}/${var.gcp_credentials_file}")
}

data "google_client_config" "default" {}

provider "kubernetes" {
  alias                  = "gcp"
  host                   = "https://${module.gcp_env.module.k8s.gke_cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.gcp_env.module.k8s.gke_cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  alias      = "gcp"
  kubernetes = kubernetes.gcp
}





# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = ">= 6.12.0"
#     }
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#     random = {
#       source  = "hashicorp/random"
#       version = "~> 3.0"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = ">= 2.8.0"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = ">= 2.0"
#     }
#   }

#   required_version = ">= 1.3.0"
# }

# provider "random" {}

# # AWS
# provider "aws" {
#   region = var.aws_region
# }

# provider "aws" {
#   alias  = "aws"
#   region = var.aws_region
# }


# data "aws_eks_cluster_auth" "eks" {
#   name = module.aws_env.module.k8s.cluster_name
# }

# provider "kubernetes" {
#   alias                  = "aws"
#   host                   = module.aws_env.module.k8s.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.aws_env.module.k8s.cluster_ca_certificate)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# provider "helm" {
#   alias      = "aws"
#   kubernetes = kubernetes.aws
# }

# # GCP
# provider "google" {

#   project     = var.gcp_project_id
#   region      = var.gcp_region
#   credentials = file("${path.module}/${var.gcp_credentials_file}")
# }

# # Aliased Google provider (needed because modules expect google.gcp)
# provider "google" {
#   alias       = "gcp"
#   project     = var.gcp_project_id
#   region      = var.gcp_region
#   credentials = file("${path.module}/${var.gcp_credentials_file}")
# }

# data "google_client_config" "default" {}

# provider "kubernetes" {
#   alias                  = "gcp"
#   host                   = "https://${module.gcp_env.module.k8s.gke_cluster_endpoint}"
#   cluster_ca_certificate = base64decode(module.gcp_env.module.k8s.gke_cluster_ca_certificate)
#   token                  = data.google_client_config.default.access_token
# }

# provider "helm" {
#   alias      = "gcp"
#   kubernetes = kubernetes.gcp
# }
