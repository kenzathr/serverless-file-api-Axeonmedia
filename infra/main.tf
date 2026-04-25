terraform {
  backend "s3" {
    bucket = "kanza-file-api-tfstate"
    key    = "dev/terraform.tfstate"
    region = "eu-west-3"
  }

  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_cloudfront_origin_access_control" "default" { 
  name                              = "OAC for ${var.project_name}"
  description                       = "Origin Access Control for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source             = "./modules/iam"
  project_name       = var.project_name
  bucket_arn         = module.s3.bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  environment  = var.environment
}

module "lambda" {
  source              = "./modules/lambda"
  project_name        = var.project_name
  environment         = var.environment
  lambda_role_arn     = module.iam.lambda_role_arn
  bucket_id           = module.s3.bucket_id
  dynamodb_table_name = module.dynamodb.table_name
}

module "api_gateway" {
  source               = "./modules/api_gateway"
  project_name         = var.project_name
  environment          = var.environment
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}

module "cloudfront" {
  source                      = "./modules/cloudfront"
  project_name                = var.project_name
  environment                 = var.environment
  bucket_id                   = module.s3.bucket_id
  bucket_arn                  = module.s3.bucket_arn
  bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  public_key_pem              = var.public_key_pem
  origin_access_control_id    = aws_cloudfront_origin_access_control.default.id
}
# 1. Le réservoir d'utilisateurs
resource "aws_cognito_user_pool" "axeon_user_pool" {
  name = "axeon-media-users"

  # On se connecte avec l'email
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

# 2. Le "Client" pour ton interface Web
resource "aws_cognito_user_pool_client" "axeon_client" {
  name         = "axeon-web-client"
  user_pool_id = aws_cognito_user_pool.axeon_user_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}
