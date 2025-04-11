output "vpn_endpoint" {
  description = "Endpoint do servidor OpenVPN"
  value       = module.openvpn.public_ip
}