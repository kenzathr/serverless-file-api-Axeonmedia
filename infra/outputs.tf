output "url_api" {
  description = "URL de l'API Gateway"
  value       = "${module.api_gateway.invoke_url}/fichiers/{file_key}"
}

output "domaine_cloudfront" {
  description = "Domaine CloudFront"
  value       = module.cloudfront.domain_name
}

output "nom_bucket_s3" {
  description = "Nom du bucket S3"
  value       = module.s3.bucket_id
}

output "table_dynamodb" {
  description = "Nom de la table DynamoDB"
  value       = module.dynamodb.table_name
}
