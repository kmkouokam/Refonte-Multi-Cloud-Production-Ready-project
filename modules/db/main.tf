locals {
  is_aws = lower(var.cloud_provider) == "aws"
  is_gcp = lower(var.cloud_provider) == "gcp"
}

# ------------------------
# Enable Service Networking API
# ------------------------
resource "google_project_service" "servicenetworking" {
  project = var.gcp_project_id
  service = "servicenetworking.googleapis.com"
}

# ------------------------
# Reserve a private IP range for Cloud SQL
# ------------------------
resource "google_compute_global_address" "private_ip_range" {
  name          = "google-managed-services-${var.vpc_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.gcp_vpc_self_link
}

# Create a private service connection for Cloud SQL:VPC Peering connection
resource "google_service_networking_connection" "private_vpc_connection" {
  count = local.is_gcp ? 1 : 0

  network                 = var.gcp_vpc_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
  depends_on              = [google_project_service.servicenetworking]
}

# ----------------------
# AWS RDS PostgreSQL
# ----------------------
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
  skip_final_snapshot    = true
  publicly_accessible    = false
  depends_on             = [google_service_networking_connection.private_vpc_connection]
}

# ----------------------
# GCP Cloud SQL PostgreSQL
# ----------------------
resource "google_sql_database_instance" "postgres" {
  count            = local.is_gcp ? 1 : 0
  name             = var.db_name
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.db_instance_class
    ip_configuration {
      ipv4_enabled    = true
      private_network = var.gcp_vpc_self_link # for GCP private network
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_user" "postgres_user" {
  count    = local.is_gcp ? 1 : 0
  name     = var.db_username
  instance = google_sql_database_instance.postgres[0].name
  password = var.db_password
}

# ------------------------
# Optional Custom Database
# ------------------------
resource "google_sql_database" "custom" {
  count    = local.is_gcp && var.create_custom_db ? 1 : 0
  name     = var.db_name
  instance = google_sql_database_instance.postgres[0].name
}
