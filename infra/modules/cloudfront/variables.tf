variable "project_name" {
  description = "Nom du projet pour le tagging des ressources Axeon Media"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev/prod)"
  type        = string
}

variable "bucket_id" {
  description = "ID du bucket S3 contenant les rendus 3D"
  type        = string
}

variable "bucket_arn" {
  description = "ARN du bucket pour la configuration des politiques IAM"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "Domaine regional du bucket S3 utilise par CloudFront"
  type        = string
}

# --- AJOUT POUR LA SÉCURITÉ CLOUDFRONT ---
variable "public_key_pem" {
  description = "Contenu de la cle publique pour CloudFront"
  type        = string
}
