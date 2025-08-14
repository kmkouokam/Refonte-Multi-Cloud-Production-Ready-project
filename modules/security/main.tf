module "vpc" {
  source         = "../../modules/vpc"
  cloud_provider = var.cloud_provider
  vpc_cidr       = var.vpc_cidr

}


locals {
  is_aws = lower(var.cloud) == "aws"
  is_gcp = lower(var.cloud) == "gcp"
}

# -----------------------
# AWS Security Resources
# -----------------------
resource "aws_iam_role" "this" {
  count = local.is_aws ? length(var.aws_iam_roles) : 0

  name               = var.aws_iam_roles[count.index]
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_security_group" "allow_access" {
  count       = local.is_aws ? 1 : 0
  name        = "allow-access"
  description = "Allow SSH and HTTPS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------
# GCP Security Resources
# -----------------------
resource "google_compute_firewall" "allow_access" {
  count   = local.is_gcp ? 1 : 0
  name    = "allow-access"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  source_ranges = var.allowed_cidrs
}

resource "google_project_iam_binding" "bindings" {
  for_each = local.is_gcp ? var.gcp_iam_bindings : {}
  project  = "prod-251618-359501"
  role     = each.key
  members  = each.value
}

# -----------------------
# KMS (Optional)
# -----------------------
resource "aws_kms_key" "encryption" {
  count                   = local.is_aws && var.kms_key_name != "" ? 1 : 0
  description             = "KMS key for AWS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Optional alias for easy reference
resource "aws_kms_alias" "encryption_alias" {
  name          = var.aws_kms_alias
  count         = local.is_aws && var.kms_key_name != "" ? 1 : 0
  depends_on    = [aws_kms_key.encryption]
  target_key_id = aws_kms_key.encryption[count.index].key_id
}

resource "google_kms_key_ring" "this" {
  count    = local.is_gcp && var.kms_key_name != "" ? 1 : 0
  name     = var.kms_key_name
  location = var.gcp_region
}

resource "google_kms_crypto_key" "this" {
  count    = local.is_gcp && var.kms_key_name != "" ? 1 : 0
  name     = "${var.kms_key_name}-crypto"
  key_ring = google_kms_key_ring.this[0].id
  purpose  = "ENCRYPT_DECRYPT"
}




# -------------------------
# Generate Random Password
# -------------------------
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# -------------------------
# AWS Secrets Manager
# -------------------------
resource "aws_secretsmanager_secret" "db_password" {
  count = local.is_aws ? 1 : 0
  name  = "${var.project}-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count         = local.is_aws ? 1 : 0
  secret_id     = aws_secretsmanager_secret.db_password[0].id
  secret_string = random_password.db_password.result
}

# Data block to retrieve AWS secret
data "aws_secretsmanager_secret" "db_password" {
  count = local.is_aws ? 1 : 0
  name  = "${var.project}-db-password"
  depends_on = [
    aws_secretsmanager_secret_version.db_password
  ]
}

data "aws_secretsmanager_secret_version" "db_password" {
  count     = local.is_aws ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.db_password[0].id
}

# -------------------------
# Google Secret Manager
# -------------------------
resource "google_secret_manager_secret" "db_password" {
  count     = local.is_gcp ? 1 : 0
  secret_id = "${var.project}-db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  count       = local.is_gcp ? 1 : 0
  secret      = google_secret_manager_secret.db_password[0].name
  secret_data = random_password.db_password.result
}

# Data block to retrieve GCP secret
data "google_secret_manager_secret" "db_password" {
  count     = local.is_gcp ? 1 : 0
  secret_id = "${var.project}-db-password"
  depends_on = [
    google_secret_manager_secret_version.db_password
  ]
}

data "google_secret_manager_secret_version" "db_password" {
  count   = local.is_gcp ? 1 : 0
  secret  = data.google_secret_manager_secret.db_password[0].name
  version = "latest"
}
