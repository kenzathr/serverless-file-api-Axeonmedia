output "bucket_id" {
  value = aws_s3_bucket.files.id
}

output "bucket_arn" {
  value = aws_s3_bucket.files.arn
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.files.bucket_regional_domain_name
}
