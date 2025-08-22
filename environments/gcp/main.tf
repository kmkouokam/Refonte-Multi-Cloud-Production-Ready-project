module "vpc" {
  source             = "../../modules/vpc"
  cloud_provider     = var.cloud_provider
  vpc_name           = var.vpc_name
  public_subnets     = length(var.public_subnet_cidr)
  private_subnets    = length(var.private_subnet_cidr)
  gcp_region         = var.gcp_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zone

}


module "k8s" {
  source            = "../../modules/kubernetes"
  cloud_provider    = "gcp"
  cluster_name      = "my-gcp-cluster"
  region            = "us-central1"
  vpc_name          = var.vpc_name
  gcp_project_id    = var.gcp_project_id
  gcp_network       = length(var.public_subnet_cidr) > 0 ? var.public_subnet_cidr[0] : null
  gcp_subnetwork    = var.gcp_subnetwork
  public_subnet_ids = module.vpc.public_subnet_ids
}


module "gcp_security" {
  source = "../../modules/security"
  # cloud         = "gcp"
  allowed_cidrs = ["0.0.0.0/0"]
  vpc_name      = var.vpc_name
  gcp_region    = var.gcp_region
  kms_key_name  = var.kms_key_name
  gcp_iam_bindings = {
    "roles/compute.networkAdmin" = ["serviceAccount:${var.gcp_service_account_email}"]
  }
}

module "gcp_db" {
  source            = "../../modules/db"
  cloud_provider    = "gcp"
  db_name           = var.db_name
  db_username       = var.db_username
  db_instance_class = var.db_instance_class # GCP machine type
  db_storage_size   = var.db_storage_size
  env               = var.env
  region            = var.gcp_region
  db_password       = module.gcp_security.db_password
  gcp_vpc_self_link = module.vpc.gcp_vpc_self_link
  depends_on        = [module.gcp_security, module.vpc, module.k8s]
  gcp_project_id    = var.gcp_project_id
  vpc_name          = var.vpc_name
  create_custom_db  = var.create_custom_db
}



