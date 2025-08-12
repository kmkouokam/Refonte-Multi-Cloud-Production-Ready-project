# This is a reusable VPC module for AWS and GCP.
# Logic is switched based on the cloud_provider variable.

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
# GCP VPC + Subnets + NAT + IGW
# ----------------------
resource "google_compute_network" "main" {
  count                   = var.cloud_provider == "gcp" ? 1 : 0
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  count         = var.cloud_provider == "gcp" ? length(var.public_subnets) : 0
  name          = "${var.name_prefix}-public-${count.index}"
  ip_cidr_range = var.public_subnets[count.index]
  region        = var.gcp_region
  network       = google_compute_network.main[0].name
}

resource "google_compute_subnetwork" "private" {
  count                    = var.cloud_provider == "gcp" ? length(var.private_subnets) : 0
  name                     = "${var.name_prefix}-private-${count.index}"
  ip_cidr_range            = var.private_subnets[count.index]
  region                   = var.gcp_region
  network                  = google_compute_network.main[0].name
  private_ip_google_access = true
}

resource "google_compute_router" "main" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  name    = "${var.name_prefix}-router"
  region  = var.gcp_region
  network = google_compute_network.main[0].name
}

resource "google_compute_address" "nat_ip" {
  count  = var.cloud_provider == "gcp" ? 1 : 0
  name   = "${var.name_prefix}-nat-ip"
  region = var.gcp_region
}

resource "google_compute_router_nat" "nat" {
  count                              = var.cloud_provider == "gcp" ? 1 : 0
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.main[0].name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip[0].self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

