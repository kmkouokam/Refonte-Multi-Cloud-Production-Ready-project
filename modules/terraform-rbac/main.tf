###############################################
# Terraform Role Based Access Control (RBAC) for AWS / EKS
###############################################

#------------------------------
#  k8s service account for GitHub Runner IAM Role
#------------------------------
resource "kubernetes_service_account" "github_runner" {
  provider = kubernetes.bootstrap
  metadata {
    name      = "github-actions-runner"
    namespace = "default"
  }
}

#------------------------------
# Cluster Role for Argo Rollouts
#------------------------------

resource "kubernetes_cluster_role" "argo_rollouts" {
  provider = kubernetes.bootstrap
  metadata {
    name = "argo-rollouts-role"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["rollouts"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

#------------------------------
# Cluster Role Binding for Argo Rollouts to GitHub Runner Service Account
#------------------------------


resource "kubernetes_cluster_role_binding" "argo_rollouts_runner_binding" {
  provider = kubernetes.bootstrap
  metadata {
    name = "argo-rollouts-runner-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argo_rollouts.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.github_runner.metadata[0].name
    namespace = kubernetes_service_account.github_runner.metadata[0].namespace
  }
}




# ----------------------------------------
# IAM Role Terraform will use inside EKS
# ----------------------------------------
resource "aws_iam_role" "terraform" {
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
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


###############################################
# Read Cluster
###############################################

data "aws_eks_cluster" "eks" {
  name       = var.cluster_name
  depends_on = [var.wait_for_k8s]
}

# ----------------------------------------
# Kubernetes bootstrap provider to patch aws-auth
# ----------------------------------------
provider "kubernetes" {
  alias                  = "bootstrap"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
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
  provisioner "local-exec" {
    command = "echo 'Waiting for EKS endpoint...' && sleep 30"
  }
  depends_on = [var.wait_for_k8s]
}

# ----------------------------------------
# Patch aws-auth ConfigMap (instead of recreating)
# ----------------------------------------
resource "kubernetes_config_map_v1_data" "aws_auth_patch" {
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
            rolearn  = aws_iam_role.terraform.arn
            username = "terraform"
            groups   = ["system:masters"]
          },
           
        ],
        local.all_extra_roles
      )
    )

    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::435329769674:user/refonte"
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

 
