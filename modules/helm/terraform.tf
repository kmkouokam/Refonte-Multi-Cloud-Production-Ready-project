terraform {
  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      configuration_aliases = [kubernetes.aws, kubernetes.gcp]
    }
    helm = {
      source                = "hashicorp/helm"
      configuration_aliases = [helm.aws, helm.gcp]
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.aws]
    }
    google = {
      source                = "hashicorp/google"
      configuration_aliases = [google.gcp]
    }
  }
}
