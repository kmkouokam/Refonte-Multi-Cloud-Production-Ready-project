locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}

locals {
  flask_namespace = "flask-app"
  flask_release   = "flask-app-release"
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



module "k8s" {
  count          = local.is_gcp ? 1 : 0
  source         = "../../modules/kubernetes"
  cloud_provider = "gcp"
  cluster_name   = "my-gcp-cluster"
  gcp_region     = var.gcp_region

  gcp_project_id    = var.gcp_project_id
  gcp_network       = module.vpc.gcp_network_name
  gcp_subnetwork    = module.vpc.gcp_private_subnet_name
  public_subnet_ids = module.vpc.aws_public_subnet_ids

  depends_on = [module.vpc.enabled_services, module.vpc] # <– ensures APIs are ready before k8s runs

  providers = {
    kubernetes     = kubernetes.gcp
    kubernetes.gcp = kubernetes.gcp
    kubernetes.aws = kubernetes.aws

  }
}


module "gcp_security" {
  count            = local.is_gcp ? 1 : 0
  source           = "../../modules/security"
  cloud_provider   = var.cloud_provider
  env              = var.env
  project          = var.project
  secret_name      = "mygcpdb-password"
  aws_region       = var.aws_region
  helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-gcp.yaml"
  name_suffix      = var.name_prefix
  db_name          = module.gcp_db.db_name
  db_username      = module.gcp_db.db_username
  gcp_region       = var.gcp_region
  kms_key_name     = var.kms_key_name
  gcp_iam_bindings = {
    "roles/compute.networkAdmin" = ["serviceAccount:${var.gcp_service_account_email}"]
  }
  db_endpoint = module.gcp_db.db_endpoint
  depends_on  = [module.vpc, module.k8s]

  providers = {
    kubernetes     = kubernetes.gcp
    helm           = helm.gcp
    helm.gcp       = helm.gcp
    helm.aws       = helm.aws
    kubernetes.gcp = kubernetes.gcp
    kubernetes.aws = kubernetes.aws

  }

}

module "gcp_db" {
  count             = local.is_gcp ? 1 : 0
  source            = "../../modules/db"
  cloud_provider    = "gcp"
  db_name           = var.db_name
  db_username       = var.db_username
  db_instance_class = var.db_instance_class # GCP machine type
  db_storage_size   = var.db_storage_size
  env               = var.env
  gcp_region        = var.gcp_region
  db_password       = module.gcp_security.db_password
  gcp_vpc_self_link = module.vpc.gcp_vpc_self_link
  depends_on        = [module.gcp_security, module.vpc, module.k8s]
  gcp_project_id    = var.gcp_project_id
  name_suffix       = "${var.project}-${var.env}"
  gcp_network_name  = module.vpc.gcp_network_name
  gcp_subnet_name   = module.vpc.gcp_private_subnet_name
  gcp_web_fw_name   = module.vpc.gcp_web_fw_name
  gcp_db_fw_name    = module.vpc.gcp_db_fw_name
  create_custom_db  = var.create_custom_db
  aws_db_sg_id      = module.vpc.aws_db_sg_id
  aws_vpc_id        = module.vpc.aws_vpc_id
  aws_web_sg_id     = module.vpc.aws_web_sg_id

}

module "helm" {
  count          = local.is_gcp ? 1 : 0
  source         = "../../modules/helm"
  cloud_provider = var.cloud_provider
  db_endpoint    = module.gcp_db.db_endpoint

  helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-gcp.yaml"
  depends_on       = [module.gcp_db]
  flask_namespace  = local.flask_namespace
  flask_release    = local.flask_release
  providers = {
    helm.gcp = helm.gcp
    helm     = helm.gcp
    helm.aws = helm.aws


  }
}





