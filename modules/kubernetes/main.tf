# modules/k8s/main.tf

locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}

resource "random_id" "suffix" {
  byte_length = 2
}

################
# AWS EKS Setup
################
resource "aws_iam_role" "eks_cluster_role" {
  count = local.is_aws ? 1 : 0

  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_role[0].json
}

data "aws_iam_policy_document" "eks_assume_role" {
  count = local.is_aws ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = local.is_aws ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

# Node Role + Instance Profile
resource "aws_iam_role" "eks_node_role" {
  count = local.is_aws ? 1 : 0

  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume[0].json

}

data "aws_iam_policy_document" "eks_node_assume" {
  count = local.is_aws ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

resource "aws_iam_instance_profile" "eks_node_instance_profile" {
  count = local.is_aws ? 1 : 0
  name  = "${var.cluster_name}-node-profile"
  role  = aws_iam_role.eks_node_role[0].name

  depends_on = [aws_iam_role.eks_node_role, aws_iam_instance_profile.eks_node_instance_profile]
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  count = local.is_aws ? 3 : 0
  role  = aws_iam_role.eks_node_role[0].name
  policy_arn = element([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ], count.index)

  depends_on = [aws_iam_role.eks_node_role, aws_iam_instance_profile.eks_node_instance_profile]
}

# resource "kubernetes_config_map" "aws_auth_patch" {
#   depends_on = [module.k8s] # wait for cluster to exist
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = jsonencode([{
#       rolearn  = module.kubernetes.node_role_arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups   = ["system:bootstrappers", "system:nodes"]
#     }])
#   }
# }


resource "aws_eks_cluster" "aws_eks_cluster" {
  count = local.is_aws ? 1 : 0

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[0].arn

  vpc_config {
    subnet_ids = var.public_subnet_ids
  }

  depends_on = [aws_iam_role.eks_cluster_role, aws_iam_role.eks_node_role]

}

#########################
# AWS EKS Node Group
#########################
resource "aws_eks_node_group" "aws_node_group" {
  count           = local.is_aws ? 1 : 0
  cluster_name    = aws_eks_cluster.aws_eks_cluster[0].name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role[0].arn
  subnet_ids      = var.public_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  disk_size      = 20

  depends_on = [
    aws_eks_cluster.aws_eks_cluster,
    aws_iam_role.eks_node_role,
    aws_iam_role_policy_attachment.node_policies
  ]
}



###############
#GCP GKE Setup
###############


resource "google_service_account" "gke_sa" {
  count        = local.is_gcp ? 1 : 0
  account_id   = "${var.cluster_name}-gke-sa"
  display_name = "GKE Service Account"

}

# Bind GKE service account to required roles

resource "google_project_iam_binding" "gke_sa_roles" {
  for_each = local.is_gcp ? toset([
    "roles/container.admin",
    "roles/compute.viewer",
    "roles/iam.serviceAccountUser"
  ]) : []
  project = var.gcp_project_id
  role    = each.key

  members = [
    "serviceAccount:${google_service_account.gke_sa[0].email}"
  ]
  depends_on = [google_service_account.gke_sa]

}

resource "google_container_cluster" "gcp_cluster" {
  count      = local.is_gcp ? 1 : 0
  name       = var.cluster_name
  location   = var.gcp_region
  network    = var.gcp_network
  subnetwork = var.gcp_subnetwork

  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }
  depends_on = [google_service_account.gke_sa]


}

resource "google_container_node_pool" "primary_nodes" {
  count    = local.is_gcp ? 1 : 0
  name     = "${var.cluster_name}${random_id.suffix.hex}-node-pool"
  cluster  = google_container_cluster.gcp_cluster[0].name
  location = var.gcp_region

  node_config {
    service_account = google_service_account.gke_sa[0].email
    machine_type    = "e2-medium"
    disk_size_gb    = 20

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  depends_on = [google_container_cluster.gcp_cluster, google_service_account.gke_sa]

}



# # -------------------------
# # Helm Release for AWS
# # -------------------------
# resource "helm_release" "flask_app_aws" {
#   provider = helm.aws
#   count    = local.is_aws ? 1 : 0

#   name      = "flask-app"
#   chart     = "${path.module}/../../flask_app/helm/flask-app"
#   namespace = "default"
#   values    = [file(var.helm_values_file)]

#   depends_on = [kubernetes_secret.flask_db_aws]
# }

# # -------------------------
# # Helm Release for GCP
# # -------------------------
# resource "helm_release" "flask_app_gcp" {
#   provider = helm.gcp
#   count    = local.is_gcp ? 1 : 0

#   name      = "flask-app"
#   chart     = "${path.module}/../../flask_app/helm/flask-app"
#   namespace = "default"
#   values    = [file(var.helm_values_file)]

#   depends_on = [kubernetes_secret.flask_db_gcp]
# }




