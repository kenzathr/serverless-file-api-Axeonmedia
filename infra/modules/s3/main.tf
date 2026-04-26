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

# Chiffrement AES-256
resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  bucket = aws_s3_bucket.files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configuration CORS pour les téléchargements depuis navigateur
resource "aws_s3_bucket_cors_configuration" "files" {
  bucket = aws_s3_bucket.files.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}
# Activation du chiffrement KMS pour le bucket S3
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.this.id # "this" ou le nom de ta ressource bucket dans le module

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "aws/s3" # Utilise la clé gérée par AWS (économique et efficace)
    }
    bucket_key_enabled = true # Réduit les coûts et améliore les performances
  }
}
