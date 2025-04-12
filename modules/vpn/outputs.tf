output "vpn_endpoint" {
  description = "Endpoint do servidor OpenVPN"
  value       = aws_instance.openvpn.public_ip
}