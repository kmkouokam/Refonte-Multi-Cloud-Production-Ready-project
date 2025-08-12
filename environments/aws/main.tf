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

