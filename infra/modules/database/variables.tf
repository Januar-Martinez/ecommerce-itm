variable "name_prefix" {
  description = "Prefijo para nombrar los recursos de base de datos"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subredes privadas donde viven RDS y ElastiCache"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Security Group de RDS (solo acepta tráfico de la capa web)"
  type        = string
}

variable "cache_sg_id" {
  description = "Security Group de ElastiCache (solo acepta tráfico de la capa web)"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos inicial"
  type        = string
}

variable "db_username" {
  description = "Usuario administrador de MySQL"
  type        = string
}

variable "db_password" {
  description = "Contraseña del usuario administrador de MySQL"
  type        = string
  sensitive   = true
}
