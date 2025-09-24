terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11.0"
      # configuration_aliases = [kubernetes.gcp]
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8.0"
      # configuration_aliases = [helm.gcp]
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}
