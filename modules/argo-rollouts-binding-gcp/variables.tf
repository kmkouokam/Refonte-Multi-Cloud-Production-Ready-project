 

variable "gke_service_account_name" {
  type = string
}

variable "service_account_namespace" {
  type    = string
  default = "default"
}

variable "gke_ca_certificate" {
  type = string
}

variable "gke_endpoint" {
  type = string
}


variable "argo_rollouts_role_name" {
  description = "Name of the Argo Rollouts ClusterRole"
  type        = string
   
}

variable "gke_dependency" {
  description = "Fake dependency to force ordering"
  type        = any
  default     = null
}

variable "is_gcp" {
  description = "Whether to deploy GCP resources"
  type        = bool
  default     = false
}

