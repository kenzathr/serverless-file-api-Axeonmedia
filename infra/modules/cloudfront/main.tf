# Création de la ressource Clé Publique dans AWS
resource "aws_cloudfront_public_key" "pfe_key" {
  name        = "${var.project_name}-public-key"
  comment     = "Cle pour la signature des URLs - Projet Axeon Media"
  encoded_key = var.public_key_pem
}

# Création du groupe de clés
resource "aws_cloudfront_key_group" "pfe_key_group" {
  name    = "${var.project_name}-key-group"
  comment = "Groupe de cles pour securiser les rendus 3D"
  items   = [aws_cloudfront_public_key.pfe_key.id]
}

# Distribution CloudFront sécurisée
resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  # ... (ton code pour origin et OAC)

  default_cache_behavior {
    target_origin_id       = "OrigineS3"
    viewer_protocol_policy = "redirect-to-https"
    
    # Activation de la restriction par signature
    trusted_key_groups = [aws_cloudfront_key_group.pfe_key_group.id]

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }
  }
  
  # ... (restrictions et certificat)
  restrictions { geo_restriction { restriction_type = "none" } }
  viewer_certificate { cloudfront_default_certificate = true }
}
