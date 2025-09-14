# modules/k8s/main.tf
terraform {
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 6.12.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

  }
}




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
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ], count.index)

  depends_on = [aws_iam_role.eks_node_role, aws_iam_instance_profile.eks_node_instance_profile]
}

resource "aws_eks_cluster" "aws_eks_cluster" {
  count = local.is_aws ? 1 : 0

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[0].arn

  vpc_config {
    subnet_ids = var.public_subnet_ids
  }

  depends_on = [aws_iam_role.eks_cluster_role, aws_iam_role.eks_node_role]
}

###############
#GCP GKE Setup
###############
##########################
# GCP Prereqs (APIs + IAM)
##########################
# resource "google_project_service" "container_api" {
#   count   = local.is_gcp ? 1 : 0
#   project = var.gcp_project_id
#   service = "container.googleapis.com"

#   disable_dependent_services = true # Disable dependent services to avoid issues with service dependencies  
#   disable_on_destroy         = false

#   lifecycle {
#     prevent_destroy = false
#     ignore_changes  = all
#   }
# }


# resource "google_project_service" "compute_api" {
#   count                      = local.is_gcp ? 1 : 0
#   project                    = var.gcp_project_id
#   service                    = "compute.googleapis.com"
#   disable_dependent_services = true # Disable dependent services to avoid issues with service dependencies
#   disable_on_destroy         = false
#   depends_on = [google_container_cluster.gcp_cluster,
#   google_container_node_pool.primary_nodes]

#   lifecycle {
#     prevent_destroy = false
#     ignore_changes  = all
#   }
# }

# # To enable the GCP API for secret manager
# resource "google_project_service" "secret_manager" {
#   project = var.gcp_project_id
#   service = "secretmanager.googleapis.com"
# }




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
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  depends_on = [google_container_cluster.gcp_cluster, google_service_account.gke_sa]
}


