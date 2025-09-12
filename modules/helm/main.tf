locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}

resource "helm_release" "flask_app_aws" {
  provider  = helm.aws
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
