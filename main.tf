

resource "random_password" "vpn_psk" {
  length           = 32
  special          = false
  # override_special = "!@#$%^&*()-_=+[]{}"
}

locals {
  vpn_psk_raw  = random_password.vpn_psk.result
  vpn_psk_safe = replace(local.vpn_psk_raw, "^0", "A")
}

 


module "gcp_env" {
  source           = "./environments/gcp"
  gcp_network_name = var.gcp_network_name

  gcp_web_fw_name = var.gcp_web_fw_name
  gcp_db_fw_name  = var.gcp_db_fw_name

  gcp_region           = var.gcp_region
  gcp_project_id       = var.gcp_project_id
  gcp_credentials_file = var.gcp_credentials_file
  gcp_service_account_email =  module.gcp_env.gcp_service_account_email
  gcp_service_account_name = module.gcp_env.gke_service_account_name


}


module "aws_env" {
  source            = "./environments/aws"
  gcp_vpc_self_link = module.gcp_env.gcp_vpc_self_link
  aws_region        = var.aws_region
  github_runner_role_arn = var.github_runner_role_arn
  eks_node_role_arn = var.eks_node_role_arn
 


 providers = {
   kubernetes = kubernetes
   helm = helm
 }


}

# resource "random_string" "vpn_shared_secret" {
#   length  = 32
#   special = false
# }

module "aws_gcp_vpn" {
  source = "./modules/multi_cloud_vpn"

  vpn_name          = var.vpn_name
  vpn_shared_secret = local.vpn_psk_safe

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




