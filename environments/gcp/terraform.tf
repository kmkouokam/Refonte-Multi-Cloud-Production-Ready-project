terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.0"
      # configuration_aliases = [kubernetes.gcp]
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.0"
      # configuration_aliases = [helm.gcp]
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.4.0"
    }
  }
}
