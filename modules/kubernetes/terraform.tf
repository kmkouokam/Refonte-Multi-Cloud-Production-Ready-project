terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws, aws.aws]
    }

    google = {
      source                = "hashicorp/google"
      version               = ">= 6.12.0"
      configuration_aliases = [google, google.gcp]
    }

    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.0"
      configuration_aliases = [kubernetes.aws, kubernetes.gcp]
    }

    helm = {
      source                = "hashicorp/helm"
      version               = ">= 2.8.0"
      configuration_aliases = [helm.aws, helm.gcp]
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.3.0"
}
