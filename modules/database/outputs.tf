output "table_name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.faces.name
}