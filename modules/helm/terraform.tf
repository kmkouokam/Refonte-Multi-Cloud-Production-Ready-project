terraform {
  required_providers {
    # kubernetes = {
    #   source                = "hashicorp/kubernetes"
    #   configuration_aliases = [kubernetes.gcp, kubernetes.aws]
    # }
    helm = {
      source                = "hashicorp/helm"
      configuration_aliases = [helm.gcp, helm.aws]
      version               = ">= 2.13.0"
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
