variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "Repositorio de GitHub en formato USUARIO/REPO (por ejemplo juanperez/ecommerce-itm)"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repo))
    error_message = "Usa el formato USUARIO/REPO, por ejemplo juanperez/ecommerce-itm."
  }
}

variable "github_owner_id" {
  description = "ID numérico del dueño del repositorio (aparece en el sub del diagnóstico OIDC, después de la @)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "El ID del dueño debe ser solo números, por ejemplo 87335988."
  }
}

variable "github_repo_id" {
  description = "ID numérico del repositorio (aparece en el sub del diagnóstico OIDC, después de la @ del repo)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repo_id))
    error_message = "El ID del repositorio debe ser solo números, por ejemplo 1467990271."
  }
}
