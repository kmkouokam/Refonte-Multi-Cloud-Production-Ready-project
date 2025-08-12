module "vpc" {
  source         = "../../modules/vpc"
  cloud_provider = var.cloud_provider
  vpc_cidr       = var.vpc_cidr

}


module "k8s" {
  source         = "../../modules/kubernetes"
  cloud_provider = "gcp"
  cluster_name   = "my-gcp-cluster"
  region         = "us-central1"
  # node_count        = 3
  # node_machine_type = "e2-medium"
  # gcp_project_id    = "my-gcp-project-id"
  gcp_network       = var.gcp_network
  gcp_subnetwork    = var.gcp_subnetwork
  public_subnet_ids = module.vpc.public_subnet_ids
}

