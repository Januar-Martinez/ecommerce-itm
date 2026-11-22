variable "name_prefix" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "subnet_id" {
  description = "Subred pública donde corre el servidor"
  type        = string
}

variable "web_sg_id" {
  description = "Security Group de la capa web (puerto 80)"
  type        = string
}

variable "instance_type" {
  description = "Tamaño del servidor (t3.micro es el más barato elegible)"
  type        = string
  default     = "t3.micro"
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "cache_host" {
  type = string
}

variable "aws_region" {
  description = "Región de AWS (para el driver de logs de Docker)"
  type        = string
}
