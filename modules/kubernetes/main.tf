# modules/k8s/main.tf
locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
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
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  count = local.is_aws ? 3 : 0
  role  = aws_iam_role.eks_node_role[0].name
  policy_arn = element([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ], count.index)
}

resource "aws_eks_cluster" "aws_eks_cluster" {
  count = local.is_aws ? 1 : 0

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[0].arn

  vpc_config {
    subnet_ids = var.public_subnet_ids
  }
}

################
# GCP GKE Setup
################
##########################
# GCP Prereqs (APIs + IAM)
##########################
resource "google_project_service" "container_api" {
  count   = local.is_gcp ? 1 : 0
  project = var.project_id
  service = "container.googleapis.com"
}

resource "google_project_service" "compute_api" {
  count   = local.is_gcp ? 1 : 0
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_service_account" "gke_sa" {
  count        = local.is_gcp ? 1 : 0
  account_id   = "${var.cluster_name}-gke-sa"
  display_name = "GKE Service Account"
  depends_on   = [google_project_service.compute_api, google_project_service.container_api]
}

# Bind GKE service account to required roles

resource "google_project_iam_binding" "gke_sa_roles" {
  for_each = local.is_gcp ? toset([
    "roles/container.admin",
    "roles/compute.viewer",
    "roles/iam.serviceAccountUser"
  ]) : []
  project = var.project_id
  role    = each.key

  members = [
    "serviceAccount:${google_service_account.gke_sa[0].email}"
  ]
}

resource "google_container_cluster" "gcp_cluster" {
  count      = local.is_gcp ? 1 : 0
  name       = var.cluster_name
  location   = var.region
  network    = var.gcp_network
  subnetwork = var.gcp_subnetwork

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  count    = local.is_gcp ? 1 : 0
  name     = "${var.cluster_name}-node-pool"
  cluster  = google_container_cluster.gcp_cluster[0].name
  location = var.region

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
}


