output "aws_vpn_connection_id" {
  value = aws_vpn_connection.aws_to_gcp.id
}

output "aws_vpn_tunnel_outside_ips" {
  value = [
    aws_vpn_connection.aws_to_gcp.tunnel1_address,
    aws_vpn_connection.aws_to_gcp.tunnel2_address
  ]
}

output "gcp_vpn_gateway" {
  value = google_compute_vpn_gateway.gcp_vpn_gw.self_link
}

output "gcp_router" {
  value = google_compute_router.gcp_router.self_link
}
