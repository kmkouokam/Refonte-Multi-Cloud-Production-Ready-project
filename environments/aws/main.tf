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




# Get your current public IP
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# How this works:

# data "http" queries an external API to get your public IP.

# chomp() removes any trailing newline from the response.

# "/32" means "just this single IP".

# The security group will allow only your current IP for SSH/HTTPS.

# Security module
module "aws_security" {
  source        = "../../modules/security"
  cloud         = "aws"
  aws_iam_roles = ["eksNodeRole", "appRole"]
  allowed_cidrs = ["${chomp(data.http.my_ip.response_body)}/32"]

  kms_key_name = var.aws_kms_alias
}


