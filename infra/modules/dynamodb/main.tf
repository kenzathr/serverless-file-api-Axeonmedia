resource "aws_dynamodb_table" "downloads" {
  name         = "${var.project_name}-downloads"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "download_id"

  attribute {
    name = "download_id"
    type = "S"
  }

  # Suppression automatique après 90 jours
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Projet        = var.project_name
    Environnement = var.environment
  }
}
