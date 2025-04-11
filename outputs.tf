output "instance_public_ip" {
  value = aws_eip.contador_eip.public_ip
}

output "instance_id" {
  value = aws_instance.contador.id
}