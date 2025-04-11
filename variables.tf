variable "region" {
  description = "Região AWS onde os recursos serão criados"
  default     = "us-east-1"
}

variable "smartphone_ip" {
  description = "Endereço IP do smartphone que executa o DroidCam"
  type        = "http://192.168.1.6:4747/video"
}

variable "my_ip" {
  description = "Seu endereço IP para acesso SSH"
  type        = "177.84.47.208/32"
}

variable "key_name" {
  description = "Nome do par de chaves SSH para acessar a instância EC2"
  type        = "rufus.pem"
}