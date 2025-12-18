# data "aws_eks_cluster" "eks" {
#   name       = var.cluster_name
#   depends_on = [var.wait_for_k8s]
# }

 


# ----------------------------------------
# Kubernetes bootstrap provider to patch aws-auth
# ----------------------------------------
provider "kubernetes" {
  alias                  = "bootstrap"
  host                   = var.eks_endpoint != null ? var.eks_endpoint : ""
  cluster_ca_certificate = (
    var.eks_ca_certificate != null
    ? base64decode(var.eks_ca_certificate)
    : ""
  )
  # token                  = data.aws_eks_cluster_auth.eks.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.aws_region
    ]
  }

}




#------------------------------
#  k8s service account for GitHub Runner IAM Role
#------------------------------
resource "kubernetes_service_account" "github_runner" {
  count = var.is_aws ? 1 : 0
  provider = kubernetes.bootstrap
  metadata {
    name      =  "argo-rollouts"
    namespace = var.service_account_namespace
  }
}

 


#------------------------------
# Cluster Role Binding for Argo Rollouts to GitHub Runner Service Account (AWS)
#------------------------------


resource "kubernetes_cluster_role_binding" "argo_rollouts_runner_binding" {
  count = var.is_aws ? 1 : 0
  provider = kubernetes.bootstrap
  metadata {
    name = "argo-rollouts-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.argo_rollouts_role_name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.github_runner[0].metadata[0].name
    namespace = var.service_account_namespace
  }
}


#------------------------------
# Kubernetes Services for AWS Flask App (Active and Preview)
#------------------------------
resource "kubernetes_service" "flask_app_aws_active" {
  count = var.is_aws ? 1 : 0
  provider = kubernetes.bootstrap
  metadata {
    name      = "flask-app-aws-active"
    namespace = var.service_account_namespace
  }

  spec {
    selector = { app = "flask-app-aws" }
    port {
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_service" "flask_app_aws_preview" {
  count = var.is_aws ? 1 : 0
  provider = kubernetes.bootstrap
  metadata {
    name      = "flask-app-aws-preview"
    namespace = var.service_account_namespace
  }

  spec {
    selector = { app = "flask-app-aws" }
    port {
      port        = 80
      target_port = 8080
    }
  }
}

# ----------------------------------------
# IAM Role Terraform will use inside EKS
# ----------------------------------------
resource "aws_iam_role" "terraform" {
  count = var.is_aws ? 1 : 0
  name = "${var.project}-${var.env}-tf-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com" # EKS control plane
        }
      }
    ]
  })
}

# Optional: Attach policies (e.g., admin access)
resource "aws_iam_role_policy_attachment" "terraform_admin" {
  count = var.is_aws ? 1 : 0
  role       = aws_iam_role.terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


###############################################
# Read Cluster
###############################################


# Optional: extra roles to grant system:masters
# Optional: extra roles + GitHub runner role
locals {
  github_runner_map = var.github_runner_role_arn != null ? [{
    rolearn  = var.github_runner_role_arn
    username = "github-actions"
    groups   = ["system:masters"]
  }] : []

  extra_maproles = [
    for r_arn in var.extra_role_arns : {
      rolearn  = r_arn
      username = "terraform-added-${replace(r_arn, ":", "-")}"
      groups   = ["system:masters"]
    }
  ]

  all_extra_roles = concat(local.github_runner_map, local.extra_maproles)
}
###############################################


# Wait for EKS endpoint
resource "null_resource" "wait_for_eks" {
  count = var.is_aws ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'Waiting for EKS endpoint...' && sleep 30"
  }
  depends_on = [var.wait_for_k8s]
}

# ----------------------------------------
# Patch aws-auth ConfigMap (instead of recreating)
# ----------------------------------------
resource "kubernetes_config_map_v1_data" "aws_auth_patch" {
  count = var.is_aws ? 1 : 0
  provider = kubernetes.bootstrap

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      concat(
        [
          {
            rolearn  = var.eks_node_role_arn
            username = "system:node:{{EC2PrivateDNSName}}"
            groups   = ["system:bootstrappers", "system:nodes"]
          },
          {
            rolearn  = aws_iam_role.terraform[0].arn
            username = "terraform"
            groups   = ["system:masters"]
          },

        ],
        local.all_extra_roles
      )
    )

    mapUsers = yamlencode([
      {
        userarn  = var.map_user_arn
        username = "refonte"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [
    aws_iam_role.terraform,
    aws_iam_role_policy_attachment.terraform_admin,
    var.wait_for_k8s,
    null_resource.wait_for_eks
  ]

  force = true
}

#-----------------------------
#Argocd namespace 
#-----------------------------

# resource "kubernetes_namespace" "argocd" {
#   provider = kubernetes.bootstrap
#   metadata {
#     name = "argocd"
#   }
# }


# # ------------------------------
# # ArgoCD RBAC ConfigMap
# # ------------------------------
# resource "kubernetes_config_map" "argocd_rbac" {
#   provider = kubernetes.bootstrap
#   metadata {
#     name      = "argocd-rbac-cm"
#     namespace = kubernetes_namespace.argocd.metadata[0].name
#   }

#   data = {
#     "policy.csv" = "p, role:admin, *, *, *, allow"
#     "role.csv"   = "g, admin, role:admin"
#   }
#   depends_on = [kubernetes_namespace.argocd]
# }

 



  
