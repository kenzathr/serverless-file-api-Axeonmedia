resource "aws_cloudfront_key_group" "pfe_key_group" {
  name    = "axeon-key-group"
  items   = [aws_cloudfront_public_key.pfe_key.id]
}

resource "aws_cloudfront_public_key" "pfe_key" {
  name        = "${var.project_name}-public-key"
  encoded_key = var.public_key_pem
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true

  origin {
    domain_name              = "kanza-file-api-files-dev.s3.eu-west-3.amazonaws.com"
    origin_id                = "S3Origin"
    origin_access_control_id = "E2452J5OTLZ5CR" # Ton OAC réel
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    # Utilisation du groupe de clés existant
    trusted_key_groups = [aws_cloudfront_key_group.pfe_key_group.id]

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
