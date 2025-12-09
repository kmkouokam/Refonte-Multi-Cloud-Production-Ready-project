provider "kubernetes" {
  alias                   = "bootstrap"
  host                    = var.gke_endpoint
  cluster_ca_certificate  = base64decode(var.gke_ca_certificate)
  token                   = data.google_client_config.default.access_token
}

data "google_client_config" "default" {}


# ------------------------------
# Cluster Role Binding for Argo Rollouts SA (GCP)
# ------------------------------
resource "kubernetes_cluster_role_binding" "argo_rollouts_sa_binding" {
  provider = kubernetes.bootstrap
  metadata {
    name = "argo-rollouts-binding-sa"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      =  var.argo_rollouts_role_name
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.gke_service_account_name
    namespace = var.service_account_namespace
  }
}


#------------------------------
# Kubernetes Services for GCP Flask App (Active and Preview)
#------------------------------

resource "kubernetes_service" "flask_app_gcp_active" {
  provider = kubernetes.bootstrap
  metadata {
    name      = "flask-app-gcp-active"
    namespace = "default"
  }
  spec {
    selector = { app = "flask-app-gcp" }
    port {
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_service" "flask_app_gcp_preview" {
  provider = kubernetes.bootstrap
  metadata {
    name      = "flask-app-gcp-preview"
    namespace = "default"
  }
  spec {
    selector = { app = "flask-app-gcp" }
    port {
      port        = 80
      target_port = 8080
    }
  }
}



