variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID da sub-rede pública"
  type        = string
}

variable "openvpn_users" {
  description = "Lista de usuários do OpenVPN"
  type        = list(string)
  default     = ["user1"]
}