terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.12.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0" # latest stable
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "random" {
  # No configuration required
}

#For AWS 
provider "aws" {
  region = var.aws_region
}



data "aws_eks_cluster_auth" "eks" {
  name = module.k8s.cluster_name
}

provider "kubernetes" {
  alias                  = "aws"
  host                   = module.k8s.cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# Helm provider for AWS (uses Kubernetes provider alias)
provider "helm" {
  alias      = "aws"
  kubernetes = kubernetes.aws
}

# provider "helm" {
#   alias = "aws"
#   kubernetes = {
#     host                   = module.k8s.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.k8s.cluster_ca_certificate)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }

# }



# For GCP
provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = file("${path.module}/${var.gcp_credentials_file}") # Optional if using ADC
}


data "google_client_config" "default" {}


provider "kubernetes" {
  alias                  = "gcp"
  host                   = "https://${module.k8s.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.k8s.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}


# Helm provider for GCP
provider "helm" {
  alias      = "gcp"
  kubernetes = kubernetes.gcp
}


# provider "helm" {
#   alias = "gcp"
#   kubernetes = {
#     host                   = "https://${module.k8s.cluster_endpoint}"
#     cluster_ca_certificate = base64decode(module.k8s.cluster_ca_certificate)
#     token                  = data.google_client_config.default.access_token
#   }

# }






