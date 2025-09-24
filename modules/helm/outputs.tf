# -------------------
# AWS Helm outputs
# -------------------
output "flask_app_release_name_aws" {
  value       = length(helm_release.flask_app_aws) > 0 ? helm_release.flask_app_aws[0].name : null
  description = "Helm release name for Flask app on AWS"
}

output "flask_app_namespace_aws" {
  value       = length(helm_release.flask_app_aws) > 0 ? helm_release.flask_app_aws[0].namespace : null
  description = "Helm release namespace on AWS"
}

# -------------------
# GCP Helm outputs
# -------------------
output "flask_app_release_name_gcp" {
  value       = length(helm_release.flask_app_gcp) > 0 ? helm_release.flask_app_gcp[0].name : null
  description = "Helm release name for Flask app on GCP"
}

output "flask_app_namespace_gcp" {
  value       = length(helm_release.flask_app_gcp) > 0 ? helm_release.flask_app_gcp[0].namespace : null
  description = "Helm release namespace on GCP"
}




# # -------------------
# # Helm release names
# # -------------------
# output "flask_app_release_name_aws" {
#   value       = local.is_aws ? helm_release.flask_app_aws[0].name : null
#   description = "Helm release name for Flask app on AWS"
# }

# output "flask_app_release_name_gcp" {
#   value       = local.is_gcp ? helm_release.flask_app_gcp[0].name : null
#   description = "Helm release name for Flask app on GCP"
# }

# # -------------------
# # Helm namespaces
# # -------------------
# output "flask_app_namespace_aws" {
#   value       = local.is_aws ? helm_release.flask_app_aws[0].namespace : null
#   description = "Helm release namespace on AWS"
# }

# output "flask_app_namespace_gcp" {
#   value       = local.is_gcp ? helm_release.flask_app_gcp[0].namespace : null
#   description = "Helm release namespace on GCP"
# }
