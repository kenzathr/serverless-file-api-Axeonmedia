variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, prod...)"
  type        = string
}

variable "public_key_pem" {
  description = "Clé publique pour la signature CloudFront"
  type        = string
}

# --- LES VARIABLES MANQUANTES À AJOUTER ---

variable "bucket_id" {
  description = "ID du bucket S3"
  type        = string
}

variable "bucket_arn" {
  description = "ARN du bucket S3"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "Nom de domaine régional du bucket S3"
  type        = string
}

variable "origin_access_control_id" {
  description = "ID de l'OAC CloudFront"
  type        = string
}
