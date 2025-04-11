provider "aws" {
  region = var.region
}

module "networking" {
  source        = "./modules/networking"
  smartphone_ip = var.smartphone_ip
  my_ip         = var.my_ip
}

module "vpn" {
  source        = "terraform-aws-modules/openvpn/aws"
  version       = "~> 1.0"
  vpc_id        = module.networking.vpc_id
  subnet_id     = module.networking.public_subnet_id
  openvpn_users = ["user1"]
}

module "compute" {
  source            = "./modules/compute"
  vpc_id            = module.networking.vpc_id
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.ec2_sg_id
  key_name          = var.key_name
}

module "storage" {
  source = "./modules/storage"
}

module "database" {
  source = "./modules/database"
}

module "recognition" {
  source = "./modules/recognition"
}