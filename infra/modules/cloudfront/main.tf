resource "aws_cloudfront_distribution" "cdn" {
  enabled = true

  origin {
    domain_name = var.bucket_regional_domain_name
    origin_id   = "S3Origin"
    s3_origin_config {
      origin_access_identity = "" 
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    
    # INDISPENSABLE pour la validation
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    
    trusted_key_groups = [aws_cloudfront_key_group.pfe_key_group.id]

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }
  }
  
  # ... (conserve tes blocs restrictions et viewer_certificate)
}
