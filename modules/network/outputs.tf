output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da sub-rede pública"
  value       = aws_subnet.public.id
}

output "ec2_sg_id" {
  description = "ID do grupo de segurança da EC2"
  value       = aws_security_group.ec2_sg.id
}