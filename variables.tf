variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "ami_id" {
  default = "ami-0e86e20dae9224db8"
  type    = string
}

variable "instance_type" {
  default = "t3.medium"
  type    = string
}

variable "key_name" {
    default = "rufus.pem"
    type = string
}