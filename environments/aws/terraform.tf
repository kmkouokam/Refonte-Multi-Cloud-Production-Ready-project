terraform {
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.0"
      configuration_aliases = [kubernetes.gcp, kubernetes.aws]
    }
    helm = {
      source                = "hashicorp/helm"
      version               = ">= 2.8.0"
      configuration_aliases = [helm.gcp, helm.aws]
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"

    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.12.0"

    }
  }
}




