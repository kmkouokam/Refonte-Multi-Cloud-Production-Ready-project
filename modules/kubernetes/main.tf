# modules/k8s/main.tf

locals {
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
}

resource "random_id" "suffix" {
  byte_length = 6
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

  depends_on = [aws_iam_role.eks_node_role]
}

data "aws_caller_identity" "current" {}
# SSM role
resource "aws_iam_policy" "eks_node_ssm_policy" {
  count       = local.is_aws ? 1 : 0
  name        = "${var.cluster_name}-eks-node-ssm"
  description = "Allow EKS nodes to read SSM parameters for Flask app"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/flask-app/*"
      }
    ]
  })
}




# -------------------------
# Attach node policies (explicit list -> for_each)
# -------------------------
locals {
  node_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each   = local.is_aws ? toset(local.node_policy_arns) : []
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = each.key

  depends_on = [aws_iam_role.eks_node_role,
    aws_iam_instance_profile.eks_node_instance_profile
  ]
}

 


resource "aws_eks_cluster" "aws_eks_cluster" {
  count = local.is_aws ? 1 : 0

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[0].arn

  vpc_config {
    subnet_ids = var.public_subnet_ids
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

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

  tags = {
    Name = "${var.cluster_name}-node-group-${count.index + 1}"
  }
}



###############
#GCP GKE Setup
###############
# Generate a short random suffix (4 hex chars)





resource "google_service_account" "gke_sa" {
  count        = local.is_gcp ? 1 : 0
  account_id   = substr("${replace(var.cluster_name, "_", "-")}-gke-sa-${random_id.suffix.hex}", 0, 30)
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
  name       = substr("${replace(var.cluster_name, "_", "-")}-${random_id.suffix.hex}", 0, 30)
  location   = var.gcp_region
  network    = var.gcp_network
  subnetwork = var.gcp_subnetwork
  project    = var.gcp_project_id


  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

   timeouts {
     create = "30m"
    update = "40m"
    delete = "20m"
   }

  ip_allocation_policy {}

  private_cluster_config {
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
    enable_private_endpoint = true
  }

  master_authorized_networks_config {}
    
 
  
   
  depends_on = [google_service_account.gke_sa]
}

 






resource "google_container_node_pool" "primary_nodes" {
  count    = local.is_gcp ? 1 : 0
  name     = substr("${replace(var.cluster_name, "_", "-")}-${random_id.suffix.hex}-np", 0, 39)
  cluster  = google_container_cluster.gcp_cluster[0].name
  location = var.gcp_region

  node_config {
    service_account = google_service_account.gke_sa[0].email
    machine_type    = "n2-standard-2"
    disk_size_gb    = 18
    disk_type       = "pd-balanced"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "40m"
  }

  depends_on = [google_container_cluster.gcp_cluster, google_service_account.gke_sa]

}




