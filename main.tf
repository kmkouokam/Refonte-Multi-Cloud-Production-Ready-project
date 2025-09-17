




module "aws_env" {
  source            = "./environments/aws"
  gcp_vpc_self_link = module.gcp_env.gcp_vpc_self_link
  providers = {
    aws        = aws
    aws.aws    = aws.aws
    kubernetes = kubernetes.aws
    # kubernetes.aws = kubernetes.aws
    helm = helm.aws
    # helm.aws       = helm.aws
    google = google.gcp # Only if AWS module references GCP values
    # google.gcp     = google.gcp
  }

}

module "gcp_env" {
  source           = "./environments/gcp"
  gcp_network_name = var.gcp_network_name

  gcp_web_fw_name = var.gcp_web_fw_name
  gcp_db_fw_name  = var.gcp_db_fw_name
  providers = {
    google = google.gcp
    # google.gcp     = google.gcp
    kubernetes = kubernetes.gcp
    # kubernetes.gcp = kubernetes.gcp
    helm = helm.gcp
    # helm.gcp       = helm.gcp
    aws = aws.aws # Only if GCP module references AWS values
    # aws.aws        = aws.aws
  }

}

resource "random_string" "vpn_shared_secret" {
  length  = 32
  special = false
}

module "aws_gcp_vpn" {
  source = "./modules/multi_cloud_vpn"

  vpn_name          = var.vpn_name
  vpn_shared_secret = coalesce(var.vpn_shared_secret, random_string.vpn_shared_secret.result)

  # GCP
  gcp_project_id        = var.gcp_project_id
  gcp_region            = var.gcp_region
  gcp_network_self_link = module.gcp_env.gcp_vpc_self_link
  gcp_router_asn        = 65001

  # AWS
  aws_region                  = var.aws_region
  aws_vpc_id                  = module.aws_env.aws_vpc_id
  aws_amazon_side_asn         = 64512
  aws_private_route_table_ids = module.aws_env.aws_private_route_table_ids
  aws_private_subnet_cidrs    = module.aws_env.aws_private_subnet_cidrs
  gcp_private_subnet_cidrs    = module.gcp_env.gcp_private_subnet_cidrs

  depends_on = [
    module.aws_env,
    module.gcp_env
  ]
}




