terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.0"
      # configuration_aliases = [kubernetes.aws]
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.0"

    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
