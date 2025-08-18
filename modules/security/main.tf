module "vpc" {
  source         = "../../modules/vpc"
  cloud_provider = var.cloud_provider
  vpc_cidr       = var.vpc_cidr

}


locals {
  is_aws = lower(var.cloud_provider) == "aws"
  is_gcp = lower(var.cloud_provider) == "gcp"
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
  name    = "${var.project}-${var.env}llow-access"
  network = module.vpc.gcp_vpc_self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  source_ranges = var.allowed_cidrs
  depends_on    = [module.vpc]

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
  count         = local.is_aws && var.kms_key_name != "" ? 1 : 0
  name_prefix   = "alias/${var.project}-${var.env}-${var.kms_key_name}" # prevent collisions
  target_key_id = aws_kms_key.encryption[0].key_id
}


resource "google_kms_key_ring" "encryption" {
  count    = local.is_gcp && var.kms_key_name != "" ? 1 : 0
  name     = "${var.project}-${var.env}-keyring"
  location = var.gcp_region
}

resource "google_kms_crypto_key" "encryption" {
  count           = local.is_gcp && var.kms_key_name != "" ? 1 : 0
  name            = "${var.project}-${var.env}-crypto-${var.kms_key_name}"
  key_ring        = google_kms_key_ring.encryption[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "2592000s" # 30 days
  labels = {
    environment = var.env
  }
}




# -------------------------
# Generate Random Password
# -------------------------


resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_+{}<>?"
}


# -------------------------
# Local unique secret name
# -------------------------
locals {
  secret_suffix     = formatdate("YYYY-MM-DD-HH-mm-ss", timestamp())
  secret_name_final = "${var.secret_name}-${local.secret_suffix}"
}

# # -------------------------
# # AWS Secrets Manager
# # -------------------------
resource "aws_secretsmanager_secret" "db_password" {
  count       = local.is_aws ? 1 : 0
  name_prefix = "${var.project}-${var.env}-db-password" #local.secret_name_final
  description = "Database password for environment"
  kms_key_id  = length(aws_kms_key.encryption) > 0 ? aws_kms_key.encryption[0].id : null

  tags = {
    Environment = "prod-db-secret"
  }
  lifecycle {
    prevent_destroy = false  # Set true in production to keep secret
    ignore_changes  = [name] # Prevent duplicate creations on reapply
  }
  depends_on = [aws_kms_key.encryption, aws_kms_alias.encryption_alias]
}

# Store the random password as secret value (JSON structure)
resource "aws_secretsmanager_secret_version" "db_password" {
  count     = local.is_aws ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_password[0].id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
  lifecycle {
    ignore_changes = [secret_string] # Prevent re-creation on password change
  }
  depends_on = [aws_secretsmanager_secret.db_password]
}

# Optional: Safe data source for AWS secret
data "aws_secretsmanager_secret" "db_password" {
  count      = local.is_aws && length(aws_secretsmanager_secret.db_password) > 0 ? 1 : 0
  name       = aws_secretsmanager_secret.db_password[0].name
  depends_on = [aws_secretsmanager_secret_version.db_password]
}

data "aws_secretsmanager_secret_version" "db_password" {
  count      = local.is_aws && length(data.aws_secretsmanager_secret.db_password) > 0 ? 1 : 0
  secret_id  = data.aws_secretsmanager_secret.db_password[0].id
  depends_on = [aws_secretsmanager_secret_version.db_password]
}


# -------------------------
# Google Secret Manager
# -------------------------
resource "google_secret_manager_secret" "db_password" {
  count     = local.is_gcp ? 1 : 0
  secret_id = "${var.project}-${var.env}-db-password"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = false       # Set true in production
    ignore_changes  = [secret_id] # Prevent duplicate creations on reapply
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  count  = local.is_gcp ? 1 : 0
  secret = google_secret_manager_secret.db_password[0].id
  secret_data = jsonencode({
    password = random_password.db_password.result
  })
  lifecycle {
    ignore_changes = [secret_data] # Prevent re-creation on password change
  }
  depends_on = [google_secret_manager_secret.db_password]
}

# Data block to retrieve GCP secret

data "google_secret_manager_secret" "db_password" {
  count      = local.is_gcp && length(google_secret_manager_secret.db_password) > 0 ? 1 : 0
  secret_id  = google_secret_manager_secret.db_password[0].name
  depends_on = [google_secret_manager_secret_version.db_password]
}

data "google_secret_manager_secret_version" "db_password" {
  count      = local.is_gcp && length(data.google_secret_manager_secret.db_password) > 0 ? 1 : 0
  secret     = data.google_secret_manager_secret.db_password[0].name
  version    = "latest"
  depends_on = [google_secret_manager_secret_version.db_password]
}
