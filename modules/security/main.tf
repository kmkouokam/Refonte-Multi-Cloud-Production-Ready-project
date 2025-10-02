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



resource "google_project_iam_binding" "bindings" {
  for_each = local.is_gcp ? var.gcp_iam_bindings : {}
  project  = "prod-251618-359501"
  role     = each.key
  members  = each.value

}

resource "random_id" "keyring_suffix" {
  byte_length = 4
}

# -----------------------
# KMS (Optional)
# -----------------------
resource "aws_kms_key" "encryption" {
  count                   = local.is_aws && var.kms_key_name != "" ? 1 : 0
  description             = "KMS key for AWS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  timeouts {
    create = "30m"

  }
}


# Optional alias for easy reference
resource "aws_kms_alias" "encryption_alias" {
  count         = local.is_aws && var.kms_key_name != "" ? 1 : 0
  name_prefix   = "alias/${var.project}-${var.env}-${var.kms_key_name}" # prevent collisions
  target_key_id = aws_kms_key.encryption[0].key_id

}


resource "google_kms_key_ring" "encryption" {
  count    = local.is_gcp && var.kms_key_name != "" ? 1 : 0
  name     = "${var.project}-${var.env}-keyring-${random_id.keyring_suffix.hex}"
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


# resource "random_password" "db_password" {
#   length           = 16
#   special          = true
#   override_special = "!#$%&*()-_+{}<>?"
# }


# -------------------------
# Local unique secret name
# -------------------------
locals {
  secret_suffix     = formatdate("YYYY-MM-DD-HH-mm-ss", timestamp())
  secret_name_final = local.is_aws || local.is_gcp ? "${var.secret_name}-${local.secret_suffix}" : null
}

# # -------------------------
# # AWS Secrets Manager
# # -------------------------
resource "aws_secretsmanager_secret" "db_password" {
  count       = local.is_aws ? 1 : 0
  name_prefix = "${var.project}-${var.env}-${var.secret_name}" #local.secret_name_final
  description = "Database password for environment"
  kms_key_id  = length(aws_kms_key.encryption) > 0 ? aws_kms_key.encryption[0].id : null

  tags = {
    Environment = "${var.env}-db-secret"
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
    password = var.db_password
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
  secret_id = "${var.project}-${var.env}-${var.secret_name}" #local.secret_name_final

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
    password = var.db_password
  })
  lifecycle {
    ignore_changes = [secret_data] # Prevent re-creation on password change
  }
  depends_on = [google_secret_manager_secret.db_password]

}

# Data block to retrieve GCP secret

data "google_secret_manager_secret" "db_password" {
  count      = local.is_gcp ? 1 : 0
  project    = var.gcp_project_id
  secret_id  = "${var.project}-${var.env}-${var.secret_name}"
  depends_on = [google_secret_manager_secret_version.db_password]

}

data "google_secret_manager_secret_version" "db_password" {
  count      = local.is_gcp ? 1 : 0
  project    = var.gcp_project_id
  secret     = data.google_secret_manager_secret.db_password[0].id
  version    = "latest"
  depends_on = [google_secret_manager_secret_version.db_password]

}

# # -------------------------
# # AWS Kubernetes Secret
# # -------------------------
# resource "kubernetes_secret" "flask_db_aws" {
#   provider = kubernetes.aws
#   count    = local.is_aws ? 1 : 0

#   metadata {
#     name      = "flask-app-db-secret"
#     namespace = "default"
#   }

#   data = {
#     DB_HOST     = var.db_endpoint
#     DB_PORT     = "5432"
#     DB_NAME     = var.db_name
#     DB_USER     = var.db_username
#     DB_PASSWORD = var.db_password
#     # DB_PASSWORD = jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string).password
#   }

#   type = "Opaque"
# }

# # -------------------------
# # GCP Kubernetes Secret
# # -------------------------
# resource "kubernetes_secret" "flask_db_gcp" {
#   provider = kubernetes.gcp
#   count    = local.is_gcp ? 1 : 0

#   metadata {
#     name      = "flask-app-db-secret"
#     namespace = "default"
#   }

#   data = {
#     DB_HOST     = var.db_endpoint
#     DB_PORT     = "5432"
#     DB_NAME     = var.db_name
#     DB_USER     = var.db_username
#     DB_PASSWORD = var.db_password
#     # DB_PASSWORD = jsondecode(data.google_secret_manager_secret_version.db_password[0].secret_data).password
#   }

#   type = "Opaque"
# }



# -------------------------
# Used by both clouds
#-------------------------

# resource "helm_release" "flask_app" {
#   name       = "flask-app"
#   chart      = "${path.module}/../../flask_app/helm/flask-app"
#   namespace  = "default"
#   values     = [file(var.helm_values_file)]
#   depends_on = [kubernetes_secret.flask_db_aws, kubernetes_secret.flask_db_gcp]
# }


# -------------------------
# Helm Release for AWS
# -------------------------
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



