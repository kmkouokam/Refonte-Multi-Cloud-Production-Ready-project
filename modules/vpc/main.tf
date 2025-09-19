# This is a reusable VPC module for AWS and GCP.
# Logic is switched based on the cloud_provider variable.

# Enabled APIS in GCP Cloud


resource "google_project_service" "enabled_apis" {
  for_each = var.cloud_provider == "gcp" ? toset(var.enabled_apis) : []

  project = var.gcp_project_id
  service = each.key

  disable_on_destroy = false
  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }

}

resource "random_id" "suffix" {
  byte_length = 2
}

# ----------------------
# AWS VPC + Subnets + NAT + IGW
# ----------------------
resource "aws_vpc" "main" {
  count                = var.cloud_provider == "aws" ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.name_prefix}-vpc"
  }

}

resource "aws_internet_gateway" "main" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  vpc_id = aws_vpc.main[0].id
  tags = {
    Name = "${var.name_prefix}-igw"
  }

}

resource "aws_eip" "nat" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  domain = "vpc"

}

resource "aws_nat_gateway" "main" {
  count         = var.cloud_provider == "aws" ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.name_prefix}-nat"
  }
  depends_on = [aws_internet_gateway.main]

}

resource "aws_subnet" "public" {
  count                   = var.cloud_provider == "aws" ? length(var.public_subnets) : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name_prefix}-public-${count.index}"
  }

}

resource "aws_subnet" "private" {
  count             = var.cloud_provider == "aws" ? length(var.private_subnets) : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "${var.name_prefix}-private-${count.index}"
  }

}

resource "aws_route_table" "public" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  vpc_id = aws_vpc.main[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  tags = {
    Name = "${var.name_prefix}-public-rt"
  }

}

resource "aws_route_table_association" "public" {
  count          = var.cloud_provider == "aws" ? length(var.public_subnets) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id

}

resource "aws_route_table" "private" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  vpc_id = aws_vpc.main[0].id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }
  tags = {
    Name = "${var.name_prefix}-private-rt"
  }

}

resource "aws_route_table_association" "private" {
  count          = var.cloud_provider == "aws" ? length(var.private_subnets) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id

}

# ----------------------
# AWS Security Groups
# ----------------------

# SG for web (SSH + HTTP + HTTPS)
resource "aws_security_group" "web_sg" {
  count       = var.cloud_provider == "aws" ? 1 : 0
  name        = "${var.env}-web-sg"
  description = "Allow HTTP, HTTPS, and SSH"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# SG for DB
resource "aws_security_group" "db_sg" {
  count       = var.cloud_provider == "aws" ? 1 : 0
  name        = "${var.env}-db-sg"
  description = "Allow DB traffic only from web SG"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


# ----------------------
# GCP VPC + Subnets + NAT + IGW
# ----------------------
resource "google_compute_network" "vpc_network" {
  count                           = var.cloud_provider == "gcp" ? 1 : 0
  name                            = "${var.name_prefix}-${random_id.suffix.hex}-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = var.manage_default_routes
  lifecycle {
    ignore_changes = [routing_mode]
  }


  depends_on = [google_project_service.enabled_apis]
}

resource "google_compute_subnetwork" "public" {
  count         = var.cloud_provider == "gcp" ? length(var.public_subnets) : 0
  name          = "${var.name_prefix}-public-${count.index}-${random_id.suffix.hex}"
  ip_cidr_range = var.public_subnets[count.index]
  region        = var.gcp_region
  network       = google_compute_network.vpc_network[0].name
  depends_on    = [google_compute_network.vpc_network]

}

resource "google_compute_subnetwork" "private" {
  count                    = var.cloud_provider == "gcp" ? length(var.private_subnets) : 0
  name                     = "${var.name_prefix}-private-${count.index}-${random_id.suffix.hex}"
  ip_cidr_range            = var.private_subnets[count.index]
  region                   = var.gcp_region
  network                  = google_compute_network.vpc_network[0].name
  private_ip_google_access = true
  depends_on               = [google_compute_network.vpc_network]

}

resource "google_compute_router" "main" {
  count      = var.cloud_provider == "gcp" ? 1 : 0
  name       = "${var.name_prefix}-${random_id.suffix.hex}-router"
  region     = var.gcp_region
  network    = google_compute_network.vpc_network[0].name
  depends_on = [google_compute_network.vpc_network]

}

resource "google_compute_address" "nat_ip" {
  count      = var.cloud_provider == "gcp" ? 1 : 0
  name       = "${var.name_prefix}-${random_id.suffix.hex}-nat-ip"
  region     = var.gcp_region
  depends_on = [google_compute_network.vpc_network]

}

resource "google_compute_router_nat" "nat" {
  count                              = var.cloud_provider == "gcp" ? 1 : 0
  name                               = "${var.name_prefix}-${random_id.suffix.hex}-nat"
  router                             = google_compute_router.main[0].name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip[0].self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [google_compute_address.nat_ip]

}

resource "google_compute_route" "default_internet" {
  count   = var.manage_default_routes ? 1 : 0
  name    = "${var.name_prefix}-${random_id.suffix.hex}-default-internet"
  network = length(google_compute_network.vpc_network) > 0 ? google_compute_network.vpc_network[0].id : null

  dest_range       = "0.0.0.0/0"
  next_hop_gateway = true
  depends_on = [google_compute_network.vpc_network,
    google_compute_router.main,
  google_compute_address.nat_ip]

}



# Allow HTTP, HTTPS, SSH
resource "google_compute_firewall" "web_fw" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  name    = "${var.env}-${random_id.suffix.hex}-web-fw"
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  depends_on    = [google_compute_network.vpc_network]

}

# Allow DB traffic only from web instances (tag-based)
resource "google_compute_firewall" "db_fw" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  name    = "${var.env}-${random_id.suffix.hex}-db-fw"
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["web"]
  target_tags = ["db"]
  depends_on  = [google_compute_network.vpc_network]

}
