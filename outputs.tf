output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = module.compute.public_ip
}

output "s3_backup_bucket" {
  description = "Nome do bucket S3 para backup"
  value       = module.storage.bucket_name
}

output "dynamodb_table" {
  description = "Nome da tabela DynamoDB"
  value       = module.database.table_name
}

output "rekognition_collection" {
  description = "ID da coleção Rekognition"
  value       = module.recognition.collection_id
}