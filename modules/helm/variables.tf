variable "cloud_provider" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "helm_values_file" {
  description = "Path to Helm values file"
  type        = string
}

