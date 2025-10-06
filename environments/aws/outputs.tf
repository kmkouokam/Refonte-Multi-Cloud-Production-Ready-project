output "aws_vpc_id" {
  value = module.vpc[0].aws_vpc_id
}


output "aws_private_subnet_cidrs" {
  value = module.vpc[0].aws_private_subnet_cidrs
}

output "aws_public_subnet_cidrs" {
  value = module.vpc[0].aws_public_subnet_cidrs
}


output "aws_private_route_table_ids" {
  value = module.vpc[0].private_route_table_ids
}

output "aws_db_endpoint" {
  value = module.aws_db[0].db_endpoint
}

# environments/aws/outputs.tf
output "eks_cluster_name" {
  value = module.k8s[0].cluster_name
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

output "db_endpoint" {
  value = module.aws_db[0].db_endpoint
}

# -------------------------
# AWS Helm Outputs
# -------------------------

output "flask_app_release_name_aws" {
  value       = helm_release.flask_app_aws[0].name
  description = "Helm release name for the Flask app on AWS"
}

output "flask_app_namespace_aws" {
  value       = helm_release.flask_app_aws[0].namespace
  description = "Kubernetes namespace for the Flask app on AWS"
}

output "flask_app_status_aws" {
  value       = helm_release.flask_app_aws[0].status
  description = "Status of the Flask app Helm release on AWS"
}


output "flask_app_url_aws" {
  description = "Public URL of the Flask app on AWS"
  value = try(
    "http://${data.kubernetes_service.flask_app_aws.status[0].load_balancer[0].ingress[0].hostname}",
    null
  )
  depends_on = [data.kubernetes_service.flask_app_aws]
}


# Flask App Service LoadBalancer Hostname (AWS EKS)
# output "flask_app_url_aws" {
#   description = "Public URL of the Flask app on AWS"
#   value       = "http://${data.kubernetes_service.flask_app_aws.status[0].load_balancer[0].ingress[0].hostname}"
# }

# Output the IAM role ARN
output "terraform_iam_role_arn" {
  value = aws_iam_role.terraform.arn
}



