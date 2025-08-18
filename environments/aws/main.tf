module "vpc" {
  source         = "../../modules/vpc"
  cloud_provider = var.cloud_provider
  vpc_cidr       = var.vpc_cidr

}

module "k8s" {
  source         = "../../modules/kubernetes"
  cloud_provider = "aws"
  cluster_name   = "my-aws-cluster"
  region         = "us-east-1"
  # node_count        = 3
  public_subnet_ids = module.vpc.public_subnet_ids
}






# How this works:

# data "http" queries an external API to get your public IP.

# chomp() removes any trailing newline from the response.

# "/32" means "just this single IP".

# The security group will allow only your current IP for SSH/HTTPS.

# Security module
module "aws_security" {
  source = "../../modules/security"
  # cloud         = "aws"
  aws_iam_roles = ["eksNodeRole", "appRole"]
  allowed_cidrs = ["0.0.0.0/0"]

  kms_key_name = var.aws_kms_alias
}


module "aws_db" {
  source                 = "../../modules/db"
  cloud_provider         = var.cloud_provider
  db_name                = var.db_name
  db_username            = var.db_username
  db_instance_class      = var.db_instance_class
  db_storage_size        = var.db_storage_size
  vpc_security_group_ids = [module.aws_security.security_group_id] # private network
  region                 = var.aws_region
  db_password            = module.aws_security.db_password
  depends_on             = [module.aws_security, module.vpc]

}


