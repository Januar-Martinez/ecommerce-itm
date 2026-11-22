output "public_ip" {
  description = "IP pública del servidor"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "ID de la instancia (para Session Manager)"
  value       = aws_instance.web.id
}
