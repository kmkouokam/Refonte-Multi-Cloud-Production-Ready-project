output "security_group_id" {
  value       = local.is_aws && length(aws_security_group.allow_access) > 0 ? aws_security_group.allow_access[0].id : ""
  description = "AWS Security Group ID"
}

output "firewall_name" {
  value       = local.is_gcp && length(google_compute_firewall.allow_access) > 0 ? google_compute_firewall.allow_access[0].name : ""
  description = "GCP Firewall Rule Name"
}

output "gcp_firewall_id" {
  value       = local.is_gcp && length(google_compute_firewall.allow_access) > 0 ? google_compute_firewall.allow_access[0].id : ""
  description = "GCP Firewall Rule ID"
}

output "kms_key_name_alias" {
  description = "KMS key alias for AWS or crypto key name for GCP"
  value = (
    local.is_aws && length(aws_kms_alias.encryption_alias) > 0 ? aws_kms_alias.encryption_alias[0].name :
    (local.is_gcp && length(google_kms_key_ring.this) > 0 ? google_kms_key_ring.this[0].name : "")
  )
}

output "kms_key_id" {
  description = "KMS key ID for AWS or GCP"
  value = (
    local.is_aws && length(aws_kms_key.encryption) > 0 ? aws_kms_key.encryption[0].key_id :
    (local.is_gcp && length(google_kms_key_ring.this) > 0 ? google_kms_key_ring.this[0].id : "")
  )
}

output "gcp_kms_key_ring_id" {
  value       = local.is_gcp && length(google_kms_key_ring.this) > 0 ? google_kms_key_ring.this[0].id : ""
  description = "GCP KMS Key Ring ID"
}


# -------------------------
# Outputs for Database Secrets
# -------------------------
output "db_password" {
  description = "Database password retrieved from the cloud secret manager"
  value = (local.is_aws && length(data.aws_secretsmanager_secret_version.db_password) > 0 ?
    data.aws_secretsmanager_secret_version.db_password[0].secret_string :
    local.is_gcp && length(data.google_secret_manager_secret_version.db_password) > 0 ?
    data.google_secret_manager_secret_version.db_password[0].secret_data :
    null
  )
  sensitive = true
}

output "db_secret_id" {
  description = "Secret resource ID in the respective cloud"
  value = (local.is_aws && length(aws_secretsmanager_secret.db_password) > 0 ?
    aws_secretsmanager_secret.db_password[0].id :
    local.is_gcp && length(google_secret_manager_secret.db_password) > 0 ?
    google_secret_manager_secret.db_password[0].id :
    null
  )

  sensitive = true
}
