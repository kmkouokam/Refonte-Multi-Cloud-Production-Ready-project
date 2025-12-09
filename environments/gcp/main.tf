locals {

  is_gcp = var.cloud_provider == "gcp"



  db_username = var.db_username != "" ? var.db_username : "flask_user"
  db_name     = var.db_name != "" ? var.db_name : "flaskdb"
}

resource "null_resource" "wait_k8s" {
  depends_on = [module.k8s]
}




resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_+{}<>?"
}


module "vpc" {
  count              = local.is_gcp ? 1 : 0
  source             = "../../modules/vpc"
  cloud_provider     = var.cloud_provider
  name_prefix        = "${var.project}-${var.env}"
  public_subnets     = var.public_subnet_cidrs
  private_subnets    = var.private_subnet_cidrs
  gcp_region         = var.gcp_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  gcp_project_id     = var.gcp_project_id
  enabled_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com"
  ]

  env = var.env

}





module "gcp_security" {
  count          = local.is_gcp ? 1 : 0
  source         = "../../modules/security"
  cloud_provider = var.cloud_provider
  env            = var.env
  project        = var.project
  secret_name    = "mygcpdb-password"
  aws_region     = var.aws_region
  # helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-gcp.yaml"
  name_suffix = var.name_prefix
  db_name     = local.db_name
  db_username = local.db_username

  db_password  = random_password.db_password.result
  gcp_region   = var.gcp_region
  kms_key_name = var.kms_key_name
  gcp_iam_bindings = {
    "roles/compute.networkAdmin" = ["serviceAccount:${var.gcp_service_account_email}"]
  }
  db_endpoint = module.gcp_db[0].db_endpoint
  depends_on  = [module.vpc, module.gcp_db]




}

# Fetch AWS security group AFTER AWS is deployed (in a later apply)
# data "aws_security_group" "aws_db_sg" {
#   id = var.aws_db_sg_id
# }

# data "aws_vpc" "aws_vpc" {
#   id = var.aws_vpc_id
# }

# data "aws_web_sg" "web_sg" {
#   id = var.aws_web_sg_id

# }

module "gcp_db" {
  count             = local.is_gcp ? 1 : 0
  source            = "../../modules/db"
  cloud_provider    = "gcp"
  db_name           = local.db_name
  db_username       = local.db_username
  db_instance_class = var.db_instance_class # GCP machine type
  db_storage_size   = var.db_storage_size
  env               = var.env
  gcp_region        = var.gcp_region
  db_password       = random_password.db_password.result
  # db_password       = var.db_password
  gcp_vpc_self_link = module.vpc[0].gcp_vpc_self_link
  depends_on        = [module.vpc]
  gcp_project_id    = var.gcp_project_id
  name_suffix       = "${var.project}-${var.env}"
  gcp_network_name  = module.vpc[0].gcp_network_name
  gcp_subnet_name   = module.vpc[0].gcp_private_subnet_name
  gcp_web_fw_name   = module.vpc[0].gcp_web_fw_name
  gcp_db_fw_name    = module.vpc[0].gcp_db_fw_name
  create_custom_db  = var.create_custom_db
  aws_db_sg_id      = module.vpc[0].aws_db_sg_id
  aws_vpc_id        = module.vpc[0].aws_vpc_id
  aws_web_sg_id     = module.vpc[0].aws_web_sg_id


}

module "k8s" {
  count          = local.is_gcp ? 1 : 0
  source         = "../../modules/kubernetes"
  cloud_provider = "gcp"
  cluster_name   = "my-gcp-cluster"
  gcp_region     = var.gcp_region

  gcp_project_id    = var.gcp_project_id
  gcp_network       = module.vpc[0].gcp_network_name
  gcp_subnetwork    = module.vpc[0].gcp_private_subnet_name
  public_subnet_ids = module.vpc[0].aws_public_subnet_ids
  # gcp_private_subnet_name = module.vpc[0].gcp_private_subnet_name

  depends_on = [module.vpc] # <– ensures APIs are ready before k8s runs

}


module "argo-rollouts-role" {
  source = "../../modules/argo-rollouts-role"
  aws_region = var.aws_region
  cluster_name = module.k8s[0].cluster_name
   
}

module "argo-rollouts-binding-gcp" {
   source = "../../modules/argo-rollouts-binding-gcp"
  gke_service_account_name = module.k8s[0].gke_service_account_name
  service_account_namespace = var.service_account_namespace
  argo_rollouts_role_name   = module.argo-rollouts-role.argo_rollouts_role_name
  gke_ca_certificate = module.k8s[0].gke_ca_certificate
  gke_endpoint      = module.k8s[0].gke_endpoint


}




