module "openvpn" {
  source         = "terraform-aws-modules/openvpn/aws"
  version        = "~> 1.0"
  vpc_id         = var.vpc_id
  subnet_id      = var.subnet_id
  openvpn_users  = var.openvpn_users
  vpc_cidr_block = "10.0.0.0/16"
}