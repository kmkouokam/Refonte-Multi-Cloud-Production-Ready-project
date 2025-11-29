terraform {
  required_version = ">= 1.3.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.0"
    }
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
    # kubernetes = {
    #   source                = "hashicorp/kubernetes"
    #   version               = ">= 2.0"
    #   configuration_aliases = [kubernetes.gcp, kubernetes.aws] # allow kubernetes.aws / kubernetes.gcp
    # }
    # helm = {
    #   source                = "hashicorp/helm"
    #   version               = ">= 2.8.0"
    #   configuration_aliases = [helm.gcp, helm.aws] # allow helm.aws / helm.gcp
    # }
  }
}

