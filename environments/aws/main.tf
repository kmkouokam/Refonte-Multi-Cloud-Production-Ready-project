locals {
  is_aws = var.cloud_provider == "aws"
  # helm_values_file = "${path.module}/../../flask_app/helm/flask-app/values-aws.yaml"

  # flask_namespace = "default"
  # flask_release   = "flask-app-release"

  db_username = var.db_username != "" ? var.db_username : "flask_user"
  db_name     = var.db_name != "" ? var.db_name : "flaskdb"
}


resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::435329769674:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:kmkouokam/Refonte-Multi-Cloud-Production-Ready-project:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}
 

 resource "aws_iam_role_policy" "github_actions_policy" {
  name = "GitHubActionsCombinedPolicy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:ListImages"
        ]
        Resource = "*"
      },
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:DescribeNodegroup",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecr_push_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}


resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_+{}<>?"
}





module "vpc" {
  count              = local.is_aws ? 1 : 0
  source             = "../../modules/vpc"
  cloud_provider     = var.cloud_provider
  vpc_cidr           = var.vpc_cidr
  name_prefix        = "${var.project}-${var.env}"
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  env                = var.env
  gcp_region         = var.gcp_region
  gcp_project_id     = var.gcp_project_id


}



# Security module
module "aws_security" {
  count          = local.is_aws ? 1 : 0
  source         = "../../modules/security"
  cloud_provider = var.cloud_provider
  aws_iam_roles  = ["eksNodeRole", "appRole"]
  # Credentials come from root locals & random_password result
  db_name          = local.db_name
  db_username      = local.db_username
  db_password      = random_password.db_password.result
  project          = var.project
  kms_key_name     = var.kms_key_name
  name_suffix      = "${var.project}-${var.env}"
  gcp_region       = var.gcp_region
  secret_name      = "myawsdb-password"
  env              = var.env
  db_endpoint      = module.aws_db[0].db_endpoint
  aws_region       = var.aws_region
   
  depends_on       = [module.aws_db, module.vpc]


}


module "aws_db" {
  count          = local.is_aws ? 1 : 0
  source         = "../../modules/db"
  cloud_provider = var.cloud_provider
  env            = var.env

  db_name           = local.db_name
  db_username       = local.db_username
  db_instance_class = var.db_instance_class
  db_storage_size   = var.db_storage_size

  aws_region    = var.aws_region
  db_password   = random_password.db_password.result
  db_subnet_ids = module.vpc[0].aws_private_subnet_ids
  depends_on = [
    module.vpc
  ]
  gcp_project_id   = var.gcp_project_id
  create_custom_db = var.create_custom_db
  gcp_network_name = module.vpc[0].gcp_network_name
  gcp_subnet_name  = module.vpc[0].gcp_private_subnet_name
  gcp_web_fw_name  = module.vpc[0].gcp_web_fw_name
  gcp_db_fw_name   = module.vpc[0].gcp_db_fw_name
  name_suffix      = "${var.project}-${var.env}"
  aws_db_sg_id     = module.vpc[0].aws_db_sg_id
  aws_vpc_id       = module.vpc[0].aws_vpc_id
  aws_web_sg_id    = module.vpc[0].aws_web_sg_id


}

module "k8s" {
  count          = local.is_aws ? 1 : 0
  source         = "../../modules/kubernetes"
  cloud_provider = var.cloud_provider
  cluster_name   = var.cluster_name
  aws_region     = var.aws_region
    
  public_subnet_ids = module.vpc[0].aws_private_subnet_ids
  gcp_project_id    = var.gcp_project_id
   
  depends_on = [module.vpc]


}


 
# module "bootstrap" {
#   source         = "../../bootstrap"
#   cluster_name  = var.cluster_name
#   eks_endpoint = module.k8s[0].eks_endpoint
#   eks_ca_certificate = module.k8s[0].eks_ca_certificate
#   github_runner_role_arn = module.actionrunner.github_runner_role_arn
#   eks_node_role_arn = module.k8s[0].eks_node_role_arn
#   eks_token = data.aws_eks_cluster_auth.eks.token
#   eks_module_dependency = module.k8s[0].aws_eks_cluster_id

#    extra_role_arns = [ 
    
#     aws_iam_role.github_actions_role.arn,
#     module.k8s[0].eks_node_role_arn
        
#     ]
#    providers = {
#     kubernetes = kubernetes
#     helm       = helm
#   }

#   depends_on = [module.k8s,
#    module.aws_db, 
#    module.aws_security,
#    null_resource.wait_for_eks
#    ]
# }



module "actionrunner" {
  source = "../../modules/ActionRunner"
  aws_vpc_id = module.vpc[0].aws_vpc_id
  aws_public_subnet_ids = module.vpc[0].aws_public_subnet_ids
  aws_region = var.aws_region
  eks_cluster_name = var.cluster_name
  ssh_key = var.ssh_key
  aws_db_password_arn = module.aws_security[0].aws_db_password_arn
   eks_node_role_arn = module.k8s[0].eks_node_role_arn
  github_runner_token = var.github_runner_token 
   depends_on = [ module.k8s, module.vpc, module.aws_security, module.aws_db ]
   }
 

module "terraform_rbac" {
  source = "../../modules/terraform-rbac"
  project = var.project
  cluster_name = var.cluster_name 
  aws_region   = var.aws_region
  env = var.env
  eks_node_role_arn = module.k8s[0].eks_node_role_arn
  github_runner_role_arn = module.actionrunner.github_runner_role_arn
    wait_for_k8s = module.k8s[0].eks_endpoint
  extra_role_arns = [ 
    aws_iam_role.github_actions_role.arn
  ]

}
 
 


