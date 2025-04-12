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

variable "my_ip" {
  description = "Seu endereço IP para acesso SSH"
  type        = string
}

variable "key_name" {
  description = "Nome do par de chaves SSH para acessar a instância EC2"
  type        = string
  default     = "rufus"
}