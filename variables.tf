variable "region" {
  description = "Região AWS onde os recursos serão criados"
  default     = "us-east-1"
}

variable "smartphone_ip" {
  description = "Endereço IP do smartphone que executa o DroidCam"
  type        = string
  default     = "10.8.0.2/32"
}

variable "my_ip" {
  description = "Seu endereço IP para acesso SSH"
  type        = string
  default     = "177.84.47.208/32"
}

variable "key_name" {
  description = "Nome do par de chaves SSH para acessar a instância EC2"
  type        = string
  default     = "rufus"
}