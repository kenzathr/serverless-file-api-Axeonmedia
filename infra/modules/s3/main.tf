resource "aws_s3_bucket" "files" {
  bucket = "${var.project_name}-files-${var.environment}"
  tags = {
    Projet        = var.project_name
    Environnement = var.environment
  }
}

# Bloquer tout accès public
resource "aws_s3_bucket_public_access_block" "files" {
  bucket                  = aws_s3_bucket.files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Activer le versionnement
resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CONFIGURATION DU CHIFFREMENT 
resource "aws_s3_bucket_server_side_encryption_configuration" "files_encryption" {
  bucket = aws_s3_bucket.files.id 

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      # En ne mettant PAS de kms_master_key_id, AWS utilise automatiquement 
      # la clé par défaut 'aws/s3'. C'est la méthode la plus stable avec Terraform.
    }
    bucket_key_enabled = true 
  }
}

# Configuration CORS pour les téléchargements
resource "aws_s3_bucket_cors_configuration" "files" {
  bucket = aws_s3_bucket.files.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"] # En prod, on mettrait l'URL de CloudFront ici
    max_age_seconds = 3600
  }
}
