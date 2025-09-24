variable "cloud_provider" {
  description = "Cloud provider (aws or gcp)"
  type        = string
}

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
}

variable "helm_values_file" {
  description = "Path to Helm values file"
  type        = string
}

variable "db_dependency" {
  description = "Optional dependency to force Helm to wait for DB module"
  type        = any
  default     = null
}
variable "flask_namespace" {
  description = "Kubernetes namespace for Flask app"
  type        = string
  default     = "default"
}
variable "flask_release" {
  description = "Helm release name for Flask app"
  type        = string
  default     = "flask-app-release"
}


