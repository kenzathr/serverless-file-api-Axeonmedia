output "table_name" {
  value = aws_dynamodb_table.downloads.name
}

output "table_arn" {
  value = aws_dynamodb_table.downloads.arn
}
