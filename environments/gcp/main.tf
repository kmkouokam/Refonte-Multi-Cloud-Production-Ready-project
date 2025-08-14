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


  gcp_network       = var.gcp_network
  gcp_subnetwork    = var.gcp_subnetwork
  public_subnet_ids = module.vpc.public_subnet_ids
}

# Get current public IP
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

##########################
# GCP Prereqs (APIs  )
##########################
resource "google_project_service" "container_api" {
  # count   = local.is_gcp ? 1 : 0
  project = var.gcp_project_id
  service = "container.googleapis.com"

  disable_dependent_services = true # Disable dependent services to avoid issues with service dependencies  
  disable_on_destroy         = true
}

resource "google_project_service" "compute_api" {
  # count                      = local.is_gcp ? 1 : 0
  project                    = var.gcp_project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = true # Disable dependent services to avoid issues with service dependencies
  disable_on_destroy         = true
}

# To enable the GCP API for secret manager
resource "google_project_service" "secret_manager" {
  project = var.gcp_project_id
  service = "secretmanager.googleapis.com"
}

module "gcp_security" {
  source        = "../../modules/security"
  cloud         = "gcp"
  allowed_cidrs = ["${chomp(data.http.my_ip.response_body)}/32"]
  vpc_name      = var.vpc_name
  gcp_region    = var.gcp_region
  kms_key_name  = var.kms_key_name
  gcp_iam_bindings = {
    "roles/compute.networkAdmin" = ["serviceAccount:${var.gcp_service_account_email}"]
  }
}


