variable "aws_region" {
  description = "Region AWS de deploiement"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Prefixe utilise pour nommer toutes les ressources"
  type        = string
  default     = "kanza-file-api"
}

variable "environment" {
  description = "Environnement de deploiement"
  type        = string
  default     = "dev"
}
variable "public_key_pem" {
  type = string
}
