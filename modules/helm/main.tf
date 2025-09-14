locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
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

resource "helm_release" "flask_app_aws" {
  provider = helm.aws

  count     = local.is_aws ? 1 : 0
  name      = "flask-app"
  chart     = "stable/flask"
  namespace = "default"

  set {
    name  = "db.host"
    value = var.db_endpoint
  }

}

resource "helm_release" "flask_app_gcp" {
  provider  = helm.gcp
  count     = local.is_gcp ? 1 : 0
  name      = "flask-app"
  chart     = "stable/flask"
  namespace = "default"

  set {
    name  = "db.host"
    value = var.db_endpoint
  }
}
