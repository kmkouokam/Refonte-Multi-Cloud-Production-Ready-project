output "aws_vpc_id" {
  value = module.vpc.aws_vpc_id
}


output "aws_private_subnet_cidrs" {
  value = module.vpc.aws_private_subnet_cidrs
}

output "aws_public_subnet_cidrs" {
  value = module.vpc.aws_public_subnet_cidrs
}


output "aws_private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "aws_db_endpoint" {
  value = module.aws_env.db_endpoint
}

# environments/aws/outputs.tf
output "eks_cluster_name" {
  value = module.k8s.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.k8s.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  value = module.k8s.cluster_ca_certificate
}



