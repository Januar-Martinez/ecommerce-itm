output "dashboard_url" {
  description = "Enlace al dashboard de CloudWatch"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${local.dashboard_name}"
}

output "sns_topic_arn" {
  description = "Tema SNS que envía las alertas por correo"
  value       = aws_sns_topic.alerts.arn
}
