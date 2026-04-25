resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  # Commentaire : index_document pour que CloudFront sache quoi charger à la racine
  default_root_object = "index.html"

  origin {
    domain_name              = var.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = var.origin_access_control_id
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    # La restriction d'accès a été supprimée ici pour permettre l'affichage du Hub.
    # La sécurité des fichiers est gérée par l'API via les URLs présignées S3.

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
