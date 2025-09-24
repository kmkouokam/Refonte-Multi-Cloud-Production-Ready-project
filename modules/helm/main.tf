locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}



# resource "helm_release" "flask_app_aws" {
#   provider = helm.aws
#   count    = local.is_aws ? 1 : 0

#   name      = "flask-app"
#   chart     = "${path.module}/../../flask_app/helm/flask-app"
#   namespace = "default"
#   values    = var.helm_values_file != "" ? [file(var.helm_values_file)] : []

#   set {
#     name  = "db.host"
#     value = var.db_endpoint
#   }

#   depends_on = []
# }

# resource "helm_release" "flask_app_gcp" {
#   provider = helm.gcp
#   count    = local.is_gcp ? 1 : 0

#   name      = "flask-app"
#   chart     = "${path.module}/../../flask_app/helm/flask-app"
#   namespace = "default"
#   values    = var.helm_values_file != "" ? [file(var.helm_values_file)] : []

#   set {
#     name  = "db.host"
#     value = var.db_endpoint
#   }

#   depends_on = []
# }

# -------------------------
# For AWS environment
# -------------------------

# AWS Helm Release
resource "helm_release" "flask_app_aws" {
  count     = local.is_aws ? 1 : 0
  name      = var.flask_release
  chart     = "${path.module}/../../flask_app/helm/flask-app"
  namespace = var.flask_namespace

  values   = [file(var.helm_values_file)]
  provider = helm.aws

  depends_on = [var.db_dependency]
}

# # -------------------------
# # AWS Kubernetes Secret
# # -------------------------
# resource "kubernetes_secret" "flask_db_aws" {
#   provider = kubernetes.aws
#   count    = local.is_aws ? 1 : 0

#   metadata {
#     name      = "flask-app-db-secret"
#     namespace = "default"
#   }

#   data = {
#     DB_HOST     = var.db_endpoint
#     DB_PORT     = "5432"
#     DB_NAME     = var.db_name
#     DB_USER     = var.db_username
#     DB_PASSWORD = jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string).password
#   }

#   type = "Opaque"
# }

# -------------------------
# For GCP environment
# -------------------------
# GCP Kubernetes Secret
# -------------------------


# # GCP Helm Release
resource "helm_release" "flask_app_gcp" {
  count     = local.is_gcp ? 1 : 0
  name      = var.flask_release
  chart     = "${path.module}/../../flask_app/helm/flask-app"
  namespace = var.flask_namespace

  values   = [file(var.helm_values_file)]
  provider = helm.gcp

  depends_on = [var.db_dependency]
}





# # -------------------------
# # GCP Kubernetes Secret
# # -------------------------
# resource "kubernetes_secret" "flask_db_gcp" {
#   provider = kubernetes.gcp
#   count    = local.is_gcp ? 1 : 0

#   metadata {
#     name      = "flask-app-db-secret"
#     namespace = "default"
#   }

#   data = {
#     DB_HOST     = var.db_endpoint
#     DB_PORT     = "5432"
#     DB_NAME     = var.db_name
#     DB_USER     = var.db_username
#     DB_PASSWORD = jsondecode(data.google_secret_manager_secret_version.db_password[0].secret_data).password
#   }

#   type = "Opaque"
# }

