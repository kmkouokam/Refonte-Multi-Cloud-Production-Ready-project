
# For AWS

output "aws_db_password" {
  value       = module.aws_env.aws_db_password
  description = "AWS Secrets Manager DB password"
  sensitive   = true
}

output "aws_db_username" {
  value       = module.aws_env.aws_db_username
  description = "AWS RDS DB username"
  sensitive   = true
}
# output "aws_db_host" {
#   value       = module.aws_env.aws_db_host
#   description = "AWS RDS DB host or IP address"
# }

output "aws_db_name" {
  value       = module.aws_env.aws_db_name
  description = "AWS RDS DB name"
}

output "aws_db_host" {
  description = "AWS RDS database endpoint used by the application"
  value = (
    var.db_host != null
    ? var.db_host
    : module.aws_env.aws_db_host
  )
}


# For GCP
output "gcp_db_password" {
  value       = module.gcp_env.gcp_db_password
  description = "GCP Secret Manager DB password"
  sensitive   = true
}

output "gcp_db_username" {
  value       = module.gcp_env.gcp_db_username
  description = "GCP Cloud SQL DB username"
  sensitive   = true
}
# output "gcp_db_host" {
#   value       = module.gcp_env.gcp_db_host
#   description = "GCP Cloud SQL DB host or IP address"
# }
output "gcp_db_name" {
  value       = module.gcp_env.gcp_db_name
  description = "GCP Cloud SQL DB name"
}
output "gcp_db_host" {
  description = "GCP Cloud SQL database endpoint used by the application"
  value = (
    var.db_host != null
    ? var.db_host
    : module.gcp_env.gcp_db_host
  )
}
