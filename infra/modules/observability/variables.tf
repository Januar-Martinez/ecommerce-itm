variable "name_prefix" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "alert_email" {
  description = "Correo que recibe las alertas"
  type        = string
}

variable "instance_id" {
  description = "ID de la instancia EC2 a vigilar"
  type        = string
}

variable "db_identifier" {
  description = "Identificador de la instancia RDS"
  type        = string
}

variable "cache_cluster_id" {
  description = "ID del clúster Redis"
  type        = string
}

variable "log_group_name" {
  description = "Grupo de logs del contenedor"
  type        = string
}
