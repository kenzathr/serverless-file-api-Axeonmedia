terraform {
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


en direct

Passer en direct
