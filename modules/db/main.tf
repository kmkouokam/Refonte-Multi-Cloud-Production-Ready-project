locals {
  is_aws = lower(var.cloud_provider) == "aws"
  is_gcp = lower(var.cloud_provider) == "gcp"
}

# ------------------------
# Random suffix (shared by AWS & GCP resources)
# ------------------------
resource "random_id" "suffix" {
  byte_length = 4
}


# ------------------------
# Enable Service Networking API (GCP only)
# ------------------------
resource "google_project_service" "servicenetworking" {
  count   = local.is_gcp ? 1 : 0
  project = var.gcp_project_id
  service = "servicenetworking.googleapis.com"
}

# ------------------------
# Reserve a private IP range for Cloud SQL (GCP only)
# ------------------------
resource "google_compute_global_address" "private_ip_range" {
  count         = local.is_gcp ? 1 : 0
  name          = "${var.vpc_name}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.gcp_vpc_self_link
}

# ------------------------
# Create Private Service Connection for Cloud SQL (VPC Peering)
# ------------------------
resource "google_service_networking_connection" "private_vpc_connection" {
  count = local.is_gcp ? 1 : 0

  network                 = var.gcp_vpc_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[0].name]

  depends_on = [
    google_project_service.servicenetworking,
    google_compute_global_address.private_ip_range
  ]
}

# ----------------------
# AWS RDS PostgreSQL (AWS only)
# ----------------------

resource "aws_db_subnet_group" "db_subnet_group" {
  count       = local.is_aws ? 1 : 0
  name        = "${var.env}-db-subnet-group"
  description = "Subnet group for RDS"
  subnet_ids  = var.db_subnet_ids
}
resource "aws_db_instance" "postgres" {
  count                  = local.is_aws ? 1 : 0
  allocated_storage      = var.db_storage_size
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group[0].name
  skip_final_snapshot    = true
  publicly_accessible    = false
}

# ----------------------
# GCP Cloud SQL PostgreSQL (GCP only)
# ----------------------
resource "google_sql_database_instance" "postgres" {
  count            = local.is_gcp ? 1 : 0
  name             = "${var.db_name}-${random_id.suffix.hex}"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.db_instance_class
    ip_configuration {
      ipv4_enabled    = true
      private_network = var.gcp_vpc_self_link
    }
  }

  deletion_protection = false

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_user" "postgres_user" {
  count    = local.is_gcp ? 1 : 0
  name     = var.db_username
  instance = google_sql_database_instance.postgres[0].name
  password = var.db_password
}

# ------------------------
# Optional Custom Database (GCP only)
# ------------------------
resource "google_sql_database" "custom" {
  count    = local.is_gcp && var.create_custom_db ? 1 : 0
  name     = var.db_name
  instance = google_sql_database_instance.postgres[0].name
}

