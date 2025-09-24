terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11.0"
      # configuration_aliases = [kubernetes.aws]
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8.0"
      # configuration_aliases = [helm.aws]
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
