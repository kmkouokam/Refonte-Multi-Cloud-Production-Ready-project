###############################################
# Terraform Role Based Access Control (RBAC) for GCP / GKE
###############################################

# Service Account for Terraform
resource "google_service_account" "terraform" {
  account_id   = "${var.project}-${var.env}-tf-sa"
  display_name = "Terraform GKE admin SA"
}

# Assign IAM roles (minimum: container.admin, adjust as needed)
resource "google_project_iam_member" "sa_container_admin" {
  project = var.gcp_project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "sa_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}



provider "kubernetes" {
  alias                  = "bootstrap"
  host                   = "https://${module.k8s[0].gke_endpoint}"
  cluster_ca_certificate = base64decode(module.k8s[0].gke_ca_certificate)
  token                  = data.google_client_config.default.access_token

}

# Bind Terraform SA to cluster-admin in GKE
resource "kubernetes_cluster_role_binding" "terraform_admin" {
  provider = kubernetes.bootstrap
  metadata {
    name = "terraform-admin-binding"
  }

  subject {
    kind      = "User"
    name      = google_service_account.terraform.email
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  # Ensure the cluster exists and SA IAM roles are applied first
  depends_on = [module.k8s,
    google_project_iam_member.sa_container_admin,
  google_project_iam_member.sa_storage_admin]
}


