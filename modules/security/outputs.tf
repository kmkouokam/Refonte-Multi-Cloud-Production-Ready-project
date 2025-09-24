

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









