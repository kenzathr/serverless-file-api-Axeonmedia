output "invoke_arn" {
  value = aws_lambda_function.presign.invoke_arn
}

output "function_name" {
  value = aws_lambda_function.presign.function_name
}
