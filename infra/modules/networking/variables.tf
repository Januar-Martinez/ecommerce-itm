variable "name_prefix" {
  description = "Prefijo para nombrar los recursos de red"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}
