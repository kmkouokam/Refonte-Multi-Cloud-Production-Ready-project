#################################
# Providers are inherited from root
#################################

locals {
  gcp_labels = {
    app = var.vpn_name
  }
}

############################
# GCP: reserve a public IP for the VPN gateway
############################
resource "google_compute_address" "gcp_vpn_ip" {
  name   = "${var.vpn_name}-gcp-vpn-ip"
  region = var.gcp_region
}

############################
# GCP: Classic VPN gateway (target gateway) + Cloud Router (BGP)
############################
resource "google_compute_vpn_gateway" "gcp_vpn_gw" {
  name    = "${var.vpn_name}-gcp-vpn-gw"
  network = var.gcp_network_self_link
  region  = var.gcp_region
}

resource "google_compute_router" "gcp_router" {
  name    = "${var.vpn_name}-cr"
  region  = var.gcp_region
  network = var.gcp_network_self_link

  bgp {
    asn               = var.gcp_router_asn
    advertise_mode    = var.gcp_router_advertise_all_subnets ? "CUSTOM" : "DEFAULT"
    advertised_groups = var.gcp_router_advertise_all_subnets ? ["ALL_SUBNETS"] : null
  }
}


############################
# AWS: VGW + attachment + Customer Gateway + VPN connection (BGP)
############################
resource "aws_vpn_gateway" "vgw" {
  amazon_side_asn = var.aws_amazon_side_asn
  tags = {
    Name = "${var.vpn_name}-vgw"
  }
}

resource "aws_vpn_gateway_attachment" "vgw_attach" {
  vpc_id         = var.aws_vpc_id
  vpn_gateway_id = aws_vpn_gateway.vgw.id
}

# The GCP side appears to AWS as a "Customer Gateway" (CGW) using the GCP VPN public IP
resource "aws_customer_gateway" "gcp" {
  bgp_asn    = var.gcp_router_asn
  ip_address = google_compute_address.gcp_vpn_ip.address
  type       = "ipsec.1"
  tags = {
    Name = "${var.vpn_name}-cgw"
  }
}

# Single AWS VPN connection (creates 2 tunnels) with BGP enabled (static_routes_only=false)
resource "aws_vpn_connection" "aws_to_gcp" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.gcp.id
  type                = "ipsec.1"
  static_routes_only  = false # BGP!

  # Let AWS assign tunnel inside /30s. We'll read them below for GCP config.
  # Optionally you can set tunnel1/2_inside_cidr to explicit /30s in 169.254.0.0/16 if you prefer.

  # Strongly recommended options
  tunnel1_ike_versions = ["ikev2"]
  tunnel2_ike_versions = ["ikev2"]

  tunnel1_preshared_key = var.vpn_shared_secret
  tunnel2_preshared_key = var.vpn_shared_secret

  tags = {
    Name = "${var.vpn_name}-aws-vpn"
  }

  depends_on = [aws_vpn_gateway_attachment.vgw_attach]
}

# Propagate learned routes from VGW into selected route tables
resource "aws_vpn_gateway_route_propagation" "propagation" {
  for_each       = zipmap(range(length(var.aws_private_route_table_ids)), var.aws_private_route_table_ids)
  route_table_id = each.value
  vpn_gateway_id = aws_vpn_gateway.vgw.id
}


############################
# GCP: Build two tunnels to the two AWS tunnel outside IPs
# and BGP peerings using AWS-provided inside IPs
############################

# TUNNEL 1
resource "google_compute_vpn_tunnel" "tunnel1" {
  name               = "${var.vpn_name}-tunnel1"
  region             = var.gcp_region
  target_vpn_gateway = google_compute_vpn_gateway.gcp_vpn_gw.id
  peer_ip            = aws_vpn_connection.aws_to_gcp.tunnel1_address
  shared_secret      = var.vpn_shared_secret
  ike_version        = 2

  depends_on = [aws_vpn_connection.aws_to_gcp]
}

resource "google_compute_router_interface" "ri1" {
  name       = "${var.vpn_name}-ri1"
  router     = google_compute_router.gcp_router.name
  region     = var.gcp_region
  ip_range   = "${aws_vpn_connection.aws_to_gcp.tunnel1_cgw_inside_address}/30" # GCP (customer) side inside /30
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "peer1" {
  name            = "${var.vpn_name}-peer1"
  router          = google_compute_router.gcp_router.name
  region          = var.gcp_region
  interface       = google_compute_router_interface.ri1.name
  peer_ip_address = aws_vpn_connection.aws_to_gcp.tunnel1_vgw_inside_address # AWS (VGW) inside IP
  peer_asn        = var.aws_amazon_side_asn
  advertise_mode  = "DEFAULT"
}

# TUNNEL 2
resource "google_compute_vpn_tunnel" "tunnel2" {
  name               = "${var.vpn_name}-tunnel2"
  region             = var.gcp_region
  target_vpn_gateway = google_compute_vpn_gateway.gcp_vpn_gw.id
  peer_ip            = aws_vpn_connection.aws_to_gcp.tunnel2_address
  shared_secret      = var.vpn_shared_secret
  ike_version        = 2

  depends_on = [aws_vpn_connection.aws_to_gcp]
}

resource "google_compute_router_interface" "ri2" {
  name       = "${var.vpn_name}-ri2"
  router     = google_compute_router.gcp_router.name
  region     = var.gcp_region
  ip_range   = "${aws_vpn_connection.aws_to_gcp.tunnel2_cgw_inside_address}/30" # GCP side inside /30
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "peer2" {
  name            = "${var.vpn_name}-peer2"
  router          = google_compute_router.gcp_router.name
  region          = var.gcp_region
  interface       = google_compute_router_interface.ri2.name
  peer_ip_address = aws_vpn_connection.aws_to_gcp.tunnel2_vgw_inside_address
  peer_asn        = var.aws_amazon_side_asn
  advertise_mode  = "DEFAULT"
}

#################################
# Notes:
# - AWS assigns tunnel inside CIDRs and exposes:
#   tunnel1_address / tunnel2_address (outside IPs),
#   tunnel{1,2}_cgw_inside_address (GCP side),
#   tunnel{1,2}_vgw_inside_address (AWS side).
#   We feed these directly into GCP interface/peer config,
#   avoiding guesswork about which IP is on which side. 
#################################
