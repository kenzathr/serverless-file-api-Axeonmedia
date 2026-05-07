variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_invoke_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}
variable "cognito_user_pool_arn" {
  description = "ARN du Cognito User Pool pour l'Authorizer API Gateway"
  type        = string
}
