output "table_name" {
  description = "Name of the DynamoDB leads table"
  value       = aws_dynamodb_table.leads.name
}

output "table_arn" {
  description = "ARN of the DynamoDB leads table"
  value       = aws_dynamodb_table.leads.arn
}