output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = module.vpc[0].aws_vpc_id
}


output "aws_private_subnet_cidrs" {
  description = "AWS private subnets cidr"
  value       = module.vpc[0].aws_private_subnet_cidrs
}

output "aws_public_subnet_cidrs" {
  value = module.vpc[0].aws_public_subnet_cidrs
}


output "aws_private_route_table_ids" {
  value = module.vpc[0].private_route_table_ids
}

output "aws_db_host" {
  value = module.aws_db[0].db_endpoint
}

output "aws_db_password" {
  value       = local.is_aws ? module.aws_security[0].aws_db_password : null
  description = "AWS DB password for Helm"
  sensitive   = true
}


output "aws_db_name" {
  value = module.aws_db[0].db_name
}

output "aws_db_username" {
  value       = module.aws_db[0].db_username
  description = "Database username for AWS"
}

# environments/aws/outputs.tf
output "aws_cluster_name" {
  value = module.k8s[0].aws_cluster_name
}

output "eks_cluster_endpoint" {
  value = module.k8s[0].eks_endpoint
}

output "eks_cluster_ca_certificate" {
  value = module.k8s[0].eks_ca_certificate
}

output "aws_db_sg_id" {
  value = module.vpc[0].aws_db_sg_id
}

output "aws_web_sg_id" {
  value = module.vpc[0].aws_web_sg_id
}

output "github_runner_role_arn" {
  description = "The ARN of the IAM role for the GitHub Actions runner."
  value       = module.actionrunner.github_runner_role_arn
}



output "eks_token" {
  value = data.aws_eks_cluster_auth.eks.token
}



output "alb_controller_irsa_arn" {
  value = module.eks.alb_controller_irsa_role_arn
}


