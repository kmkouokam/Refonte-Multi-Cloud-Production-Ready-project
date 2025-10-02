###############################################
# Terraform Role Based Access Control (RBAC) for AWS / EKS
###############################################

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

data "aws_eks_cluster" "eks" {
  name       = var.cluster_name
  depends_on = [module.k8s]
}

# ----------------------------------------
# Kubernetes bootstrap provider to patch aws-auth
# ----------------------------------------
provider "kubernetes" {
  alias                  = "bootstrap"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token

}

# Fetch existing aws-auth ConfigMap
data "kubernetes_config_map" "aws_auth" {
  provider = kubernetes.bootstrap
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  depends_on = [module.k8s]
}

# Build new mapRoles with Terraform role
locals {
  aws_auth_roles = try(jsondecode(replace(data.kubernetes_config_map.aws_auth.data["mapRoles"], "\n", "")), [])

  new_map_roles = jsonencode(
    concat(
      local.aws_auth_roles,
      [
        {
          rolearn  = aws_iam_role.terraform.arn
          username = "terraform"
          groups   = ["system:masters"]
        }
      ]
    )
  )
}

# Patch aws-auth ConfigMap with new Terraform role
resource "kubernetes_config_map" "aws_auth_patch" {
  provider = kubernetes.bootstrap
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::435329769674:user/refonte"
        username = "refonte"
        groups   = ["system:masters"]
      }
    ])

    mapRoles = yamlencode([
      {
        rolearn  = module.k8s[0].node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }



  # Ensure this runs after the IAM role is created
  depends_on = [aws_iam_role.terraform,
    aws_iam_role_policy_attachment.terraform_admin,
  module.k8s]

}
