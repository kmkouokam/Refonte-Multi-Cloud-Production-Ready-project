module "aws_env" {
  source = "./environments/aws"
  # count  = var.cloud_provider == "aws" ? 1 : 0
}

module "gcp_env" {
  source = "./environments/gcp"
  # count  = var.cloud_provider == "gcp" ? 1 : 0
}
