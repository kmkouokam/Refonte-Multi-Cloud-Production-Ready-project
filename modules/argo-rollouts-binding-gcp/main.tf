provider "kubernetes" {
  alias                   = "bootstrap"
  host                    = "https://${var.gke_endpoint}"
  cluster_ca_certificate  = base64decode(var.gke_ca_certificate)
  # client_key = base64decode(var.gke_client_key)
  token                   = data.google_client_config.default.access_token
}

data "google_client_config" "default" {}



#-------------------------------
#Readonly role
#-------------------------------
# resource "kubernetes_cluster_role" "readonly" {
#   provider = kubernetes.bootstrap
#   metadata {
#     name = "cluster-readonly"
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["nodes", "namespaces"]
#     verbs      = ["get", "list", "watch"]
#   }
# }

# ------------------------------
# Cluster Role Binding for Argo Rollouts SA (GCP)
# ------------------------------
resource "kubernetes_cluster_role_binding" "argo_rollouts_sa_binding" {
  count = var.is_gcp ? 1 : 0
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
  count = var.is_gcp ? 1 : 0
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
  count = var.is_gcp ? 1 : 0
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

#-------------------------------------
# Argocd namesapce for gcp
#-------------------------------------

# resource "kubernetes_namespace" "argocd" {
#   provider = kubernetes.bootstrap
#   metadata {
#     name = "argocd"
#   }
# }


# # ------------------------------
# # ArgoCD RBAC ConfigMap (GCP)
# # ------------------------------
# resource "kubernetes_config_map" "argocd_rbac" {
#   count    = var.is_gcp ? 1 : 0
#   provider = kubernetes.bootstrap
#   metadata {
#     name      = "argocd-rbac-cm"
#     namespace = kubernetes_namespace.argocd.metadata[0].name
#   }

#   data = {
#     "policy.csv" = "p, role:admin, *, *, *, allow"
#     "role.csv"   = "g, admin, role:admin"
#   }
# }

# # Optional: restart ArgoCD server after applying RBAC
# resource "null_resource" "restart_argocd_server_gcp" {
#   count = var.is_gcp ? 1 : 0
#   depends_on = [kubernetes_config_map.argocd_rbac]

#   provisioner "local-exec" {
#     command = "kubectl -n argocd rollout restart deployment argocd-server"
#   }
# }




