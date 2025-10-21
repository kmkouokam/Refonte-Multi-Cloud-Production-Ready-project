

output "aws_kms_key_id" {
  value       = local.is_aws && length(aws_kms_key.encryption) > 0 ? aws_kms_key.encryption[0].key_id : null
  description = "AWS KMS key id"
}

output "gcp_kms_key_id" {
  value       = local.is_gcp && length(google_kms_crypto_key.encryption) > 0 ? google_kms_crypto_key.encryption[0].id : null
  description = "GCP KMS key id"
}




# -------------------------
# Outputs for Database Secrets
# -------------------------


# AWS Secrets Manager DB password
# AWS
output "aws_db_password" {
  description = "AWS Secrets Manager DB password (decoded)"
  value = try(
    jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string)["password"],
    null
  )
  sensitive = true
}

# GCP
# output "gcp_db_password" {
#   description = "GCP Secret Manager DB password (decoded)"
#   value = try(
#     jsondecode(data.google_secret_manager_secret_version.db_password[0].secret_data)["password"],
#     null
#   )
#   sensitive = true
# }


# GCP Secret Manager DB password
output "gcp_db_password" {
  description = "GCP Secret Manager DB password (decoded)"
  value = try(
    jsondecode(data.google_secret_manager_secret_version.db_password[0].secret_data)["password"],
    null
  )
  sensitive = true
}







