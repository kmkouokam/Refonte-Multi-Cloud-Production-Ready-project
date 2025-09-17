locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}




module "vpc" {
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

  providers = {
    aws.aws    = aws.aws
    google.gcp = google.gcp

  }
}

module "k8s" {
  source         = "../../modules/kubernetes"
  cloud_provider = var.cloud_provider
  cluster_name   = var.cluster_name
  aws_region     = var.aws_region

  public_subnet_ids = module.vpc.aws_private_subnet_ids
  gcp_project_id    = var.gcp_project_id

  depends_on = [module.vpc]

  providers = {
    kubernetes.aws = kubernetes.aws
    kubernetes.gcp = kubernetes.gcp
    helm.aws       = helm.aws
    helm.gcp       = helm.gcp
    aws            = aws
    aws.aws        = aws.aws

    google     = google
    google.gcp = google.gcp
  }
}


# Security module
module "aws_security" {
  source           = "../../modules/security"
  cloud_provider   = var.cloud_provider
  aws_iam_roles    = ["eksNodeRole", "appRole"]
  db_name          = module.aws_db.db_name
  db_username      = module.aws_db.db_username
  project          = var.project
  kms_key_name     = var.kms_key_name
  name_suffix      = "${var.project}-${var.env}"
  gcp_region       = var.gcp_region
  secret_name      = "myawsdb-password"
  env              = var.env
  db_endpoint      = module.aws_db.db_endpoint
  aws_region       = var.aws_region
  helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-aws.yaml"
  depends_on       = [module.vpc]
  providers = {
    aws.aws        = aws.aws
    google.gcp     = google.gcp
    kubernetes.gcp = kubernetes.gcp
    helm.aws       = helm.aws
    helm.gcp       = helm.gcp
    kubernetes.aws = kubernetes.aws

  }
}




module "aws_db" {
  source         = "../../modules/db"
  cloud_provider = var.cloud_provider
  env            = var.env

  db_name           = var.db_name
  db_username       = var.db_username
  db_instance_class = var.db_instance_class
  db_storage_size   = var.db_storage_size

  aws_region    = var.aws_region
  db_password   = module.aws_security.db_password
  db_subnet_ids = module.vpc.aws_private_subnet_ids
  depends_on = [
    module.aws_security,
    module.vpc
  ]
  gcp_project_id   = var.gcp_project_id
  create_custom_db = var.create_custom_db
  gcp_network_name = module.vpc.gcp_network_name
  gcp_subnet_name  = module.vpc.gcp_private_subnet_name
  gcp_web_fw_name  = module.vpc.gcp_web_fw_name
  gcp_db_fw_name   = module.vpc.gcp_db_fw_name
  name_suffix      = "${var.project}-${var.env}"
  aws_db_sg_id     = module.vpc.aws_db_sg_id
  aws_vpc_id       = module.vpc.aws_vpc_id
  aws_web_sg_id    = module.vpc.aws_web_sg_id

  providers = {
    aws.aws    = aws.aws
    google.gcp = google.gcp
  }
}

module "helm" {
  source         = "../../modules/helm"
  cloud_provider = var.cloud_provider
  db_endpoint    = module.aws_db.db_endpoint

  providers = {
    kubernetes.aws = kubernetes.aws
    kubernetes.gcp = kubernetes.gcp
    helm.aws       = helm.aws
    helm.gcp       = helm.gcp
    aws.aws        = aws.aws
    google.gcp     = google.gcp
  }
  helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-aws.yaml"
  depends_on = [module.aws_security,
    module.aws_security.kubernetes_secret.flask_db_aws,
  module.k8s]
}



