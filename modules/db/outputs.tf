output "db_endpoint" {
  description = "Database endpoint"
  value = (local.is_aws ? aws_db_instance.postgres[0].address :
  local.is_gcp ? google_sql_database_instance.postgres[0].ip_address[0].ip_address : "")
}


output "gcp_sql_instance_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = local.is_gcp && length(google_sql_database_instance.postgres) > 0 ? google_sql_database_instance.postgres[0].connection_name : ""
}

output "gcp_sql_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = local.is_gcp && length(google_sql_database_instance.postgres) > 0 ? google_sql_database_instance.postgres[0].name : ""
}

output "gcp_sql_database_name" {
  description = "Name of the created custom database (if any)"
  value       = local.is_gcp && var.create_custom_db && length(google_sql_database.custom) > 0 ? google_sql_database.custom[0].name : ""
}

