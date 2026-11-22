variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefijo para nombrar todos los recursos del proyecto"
  type        = string
  default     = "tienda"
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "Nombre de la base de datos de la tienda"
  type        = string
  default     = "tienda"
}

variable "db_username" {
  description = "Usuario administrador de MySQL"
  type        = string
  default     = "tienda_admin"
}

# Sin valor por defecto a propósito: la contraseña nunca se escribe en el código.
# Se entrega con la variable de entorno TF_VAR_db_password.
variable "db_password" {
  description = "Contraseña de MySQL (12 a 41 caracteres: letras, números, _ o -)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{12,41}$", var.db_password))
    error_message = "db_password debe tener entre 12 y 41 caracteres y usar solo letras, números, guion o guion bajo."
  }
}

variable "alert_email" {
  description = "Correo que recibe las alertas de CloudWatch (se entrega con TF_VAR_alert_email)"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email debe ser un correo válido."
  }
}
