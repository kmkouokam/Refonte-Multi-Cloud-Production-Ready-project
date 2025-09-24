locals {
  is_aws           = var.cloud_provider == "aws"
  helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-aws.yaml"

  flask_namespace = "default"
  flask_release   = "flask-app-release"

  db_username = var.db_username != "" ? var.db_username : "flask_user"
  db_name     = var.db_name != "" ? var.db_name : "flaskdb"
}

# Lookup the Flask app service created by Helm on AWS
data "kubernetes_service" "flask_app_aws" {

  metadata {
    name      = local.flask_release # dynamic from locals
    namespace = local.flask_namespace
  }
  depends_on = [helm_release.flask_app_aws]
}


resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_+{}<>?"
}


resource "helm_release" "flask_app_aws" {
  count     = local.is_aws ? 1 : 0
  name      = local.flask_release
  chart     = "${path.module}/../../flask_app/helm/flask-app"
  namespace = local.flask_namespace

  values = [file(local.helm_values_file)]


  depends_on = [module.aws_db] # depends only on AWS DB
}

module "vpc" {
  count              = local.is_aws ? 1 : 0
  source             = "../../modules/vpc"
  cloud_provider     = var.cloud_provider
  vpc_cidr           = var.vpc_cidr
  name_prefix        = "${var.project}-${var.env}"
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  env                = var.env
  gcp_region         = var.gcp_region
  gcp_project_id     = var.gcp_project_id


}


# Security module
module "aws_security" {
  count          = local.is_aws ? 1 : 0
  source         = "../../modules/security"
  cloud_provider = var.cloud_provider
  aws_iam_roles  = ["eksNodeRole", "appRole"]
  # Credentials come from root locals & random_password result
  db_name          = local.db_name
  db_username      = local.db_username
  db_password      = random_password.db_password.result
  project          = var.project
  kms_key_name     = var.kms_key_name
  name_suffix      = "${var.project}-${var.env}"
  gcp_region       = var.gcp_region
  secret_name      = "myawsdb-password"
  env              = var.env
  db_endpoint      = module.aws_db[0].db_endpoint
  aws_region       = var.aws_region
  helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-aws.yaml"
  depends_on       = [module.aws_db, module.vpc]


}


# Fetch GCP firewall rule AFTER GCP is deployed
# data "google_compute_firewall" "gcp_db_fw" {
#   name    = var.gcp_db_fw_name
#   project = var.gcp_project_id
# }

# data "google_compute_network" "gcp_network" {
#   name    = var.gcp_network_name
#   project = var.gcp_project_id

# }

# data "google_compute_subnetwork" "gcp_private_subnet_name" {
#   name    = var.gcp_private_subnet_name
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }

# -------------------------
# AWS Kubernetes Secret
# -------------------------
resource "kubernetes_secret" "flask_db_aws" {
  provider = kubernetes.aws
  count    = local.is_aws ? 1 : 0

  metadata {
    name      = "flask-app-db-secret"
    namespace = "default"
  }

  data = {
    DB_HOST     = module.aws_db[0].db_endpoint
    DB_PORT     = "5432"
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = random_password.db_password.result
    # DB_PASSWORD = jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string).password
  }

  type = "Opaque"
}




module "aws_db" {
  count          = local.is_aws ? 1 : 0
  source         = "../../modules/db"
  cloud_provider = var.cloud_provider
  env            = var.env

  db_name           = local.db_name
  db_username       = local.db_username
  db_instance_class = var.db_instance_class
  db_storage_size   = var.db_storage_size

  aws_region    = var.aws_region
  db_password   = random_password.db_password.result
  db_subnet_ids = module.vpc[0].aws_private_subnet_ids
  depends_on = [
    module.vpc
  ]
  gcp_project_id   = var.gcp_project_id
  create_custom_db = var.create_custom_db
  gcp_network_name = module.vpc[0].gcp_network_name
  gcp_subnet_name  = module.vpc[0].gcp_private_subnet_name
  gcp_web_fw_name  = module.vpc[0].gcp_web_fw_name
  gcp_db_fw_name   = module.vpc[0].gcp_db_fw_name
  name_suffix      = "${var.project}-${var.env}"
  aws_db_sg_id     = module.vpc[0].aws_db_sg_id
  aws_vpc_id       = module.vpc[0].aws_vpc_id
  aws_web_sg_id    = module.vpc[0].aws_web_sg_id


}

module "k8s" {
  count          = local.is_aws ? 1 : 0
  source         = "../../modules/kubernetes"
  cloud_provider = var.cloud_provider
  cluster_name   = var.cluster_name
  aws_region     = var.aws_region

  public_subnet_ids = module.vpc[0].aws_private_subnet_ids
  gcp_project_id    = var.gcp_project_id

  depends_on = [module.vpc]


}

# module "helm" {
#   count          = local.is_aws ? 1 : 0
#   source         = "../../modules/helm"
#   cloud_provider = var.cloud_provider
#   db_endpoint    = module.aws_db.db_endpoint

#   helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-aws.yaml"
#   depends_on       = [kubernetes_secret.flask_db_aws]
#   flask_namespace  = local.flask_namespace
#   flask_release    = local.flask_release
#   providers = {
#     helm     = helm.aws
#     helm.gcp = helm.gcp
#     helm.aws = helm.aws

#   }
# }


