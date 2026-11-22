output "public_ip" {
  description = "IP pública del servidor"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "ID de la instancia (para Session Manager)"
  value       = aws_instance.web.id
}

output "log_group_name" {
  description = "Grupo de logs de CloudWatch con la salida del contenedor"
  value       = aws_cloudwatch_log_group.app.name
}
