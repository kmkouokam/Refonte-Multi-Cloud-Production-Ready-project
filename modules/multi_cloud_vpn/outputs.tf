output "aws_vpn_connection_id" {
  value = aws_vpn_connection.aws_to_gcp.id
}

output "aws_vpn_gateway_id" {
  description = "ID of the AWS VGW"
  value       = aws_vpn_gateway.vgw.id
}


output "aws_vpn_tunnel_outside_ip_addresses" {
  value = [
    aws_vpn_connection.aws_to_gcp.tunnel1_address,
    aws_vpn_connection.aws_to_gcp.tunnel2_address
  ]
}

output "gcp_vpn_gateway_id" {
  value = google_compute_vpn_gateway.gcp_vpn_gateway.id
}

output "gcp_vpn_gateway_ip" {
  description = "External IP of the GCP VPN gateway"
  value       = google_compute_address.gcp_vpn_ip.address
}

output "gcp_router_id" {
  value = google_compute_router.gcp_router.id
}
