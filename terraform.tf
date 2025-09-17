terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.aws] # allow aws.aws in modules
    }
    google = {
      source                = "hashicorp/google"
      version               = ">= 6.12.0"
      configuration_aliases = [google.gcp] # allow google.gcp in modules
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.0"
      configuration_aliases = [kubernetes.aws, kubernetes.gcp] # allow kubernetes.aws / kubernetes.gcp
    }
    helm = {
      source                = "hashicorp/helm"
      version               = ">= 2.8.0"
      configuration_aliases = [helm.aws, helm.gcp] # allow helm.aws / helm.gcp
    }
  }
}
 
