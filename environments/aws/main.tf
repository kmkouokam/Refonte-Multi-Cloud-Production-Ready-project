module "vpc" {
  source             = "../../modules/vpc"
  cloud_provider     = var.cloud_provider
  vpc_cidr           = var.vpc_cidr
  vpc_name           = "${var.project}-${var.env}"
  availability_zones = var.availability_zones
  private_subnets    = length(var.private_subnet_cidrs)
  public_subnets     = length(var.public_subnet_cidrs)
  region             = var.region
}

module "k8s" {
  source            = "../../modules/kubernetes"
  cloud_provider    = var.cloud_provider
  cluster_name      = var.cluster_name
  region            = var.region
  vpc_name          = var.vpc_name
  public_subnet_ids = module.vpc.public_subnet_ids
}


# Security module
module "aws_security" {
  source = "../../modules/security"
  # cloud         = "aws"
  aws_iam_roles = ["eksNodeRole", "appRole"]
  allowed_cidrs = ["0.0.0.0/0"]

  kms_key_name = var.kms_key_name
}


module "aws_db" {
  source                 = "../../modules/db"
  cloud_provider         = var.cloud_provider
  env                    = var.env
  vpc_name               = var.vpc_name
  db_name                = var.db_name
  db_username            = var.db_username
  db_instance_class      = var.db_instance_class
  db_storage_size        = var.db_storage_size
  vpc_security_group_ids = [module.aws_security.security_group_id] # private network
  region                 = var.aws_region
  db_password            = module.aws_security.db_password
  db_subnet_ids          = module.vpc.private_subnet_ids[0]
  depends_on             = [module.aws_security, module.vpc]


}


