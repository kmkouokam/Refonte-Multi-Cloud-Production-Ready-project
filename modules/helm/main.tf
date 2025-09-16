locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}



resource "helm_release" "flask_app_aws" {
  provider = helm.aws
  count    = local.is_aws ? 1 : 0

  name      = "flask-app"
  chart     = "${path.module}/../../flask_app/helm/flask-app"
  namespace = "default"
  values    = var.helm_values_file != "" ? [file(var.helm_values_file)] : []

  set {
    name  = "db.host"
    value = var.db_endpoint
  }

  depends_on = []
}

resource "helm_release" "flask_app_gcp" {
  provider = helm.gcp
  count    = local.is_gcp ? 1 : 0

  name      = "flask-app"
  chart     = "${path.module}/../../flask_app/helm/flask-app"
  namespace = "default"
  values    = var.helm_values_file != "" ? [file(var.helm_values_file)] : []

  set {
    name  = "db.host"
    value = var.db_endpoint
  }

  depends_on = []
}
# AWS Helm Release
# resource "helm_release" "flask_app_aws" {
#   count    = local.is_aws ? 1 : 0
#   name     = "flask-app"
#   chart    = "${path.module}/../../flask_app/helm/flask-app"
#   namespace = "default"

#   values = [file(var.helm_values_file)]
#   providers = { helm = helm.aws, kubernetes = kubernetes.aws }

#   depends_on = var.aws_secret_depends_on
# }

# # GCP Helm Release
# resource "helm_release" "flask_app_gcp" {
#   count    = local.is_gcp ? 1 : 0
#   name     = "flask-app"
#   chart    = "${path.module}/../../flask_app/helm/flask-app"
#   namespace = "default"

#   values = [file(var.helm_values_file)]
#   providers = { helm = helm.gcp, kubernetes = kubernetes.gcp }

#   depends_on = var.gcp_secret_depends_on
# }

