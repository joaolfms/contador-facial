variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID da sub-rede pública"
  type        = string
}

variable "security_group_id" {
  description = "ID do grupo de segurança"
  type        = string
}

variable "key_name" {
  description = "Nome do par de chaves SSH"
  type        = string
}