provider "random" {}

# AWS base provider
provider "aws" {
  region = var.aws_region
}

# Google base provider
provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = file("${path.module}/${var.gcp_credentials_file}")
}
