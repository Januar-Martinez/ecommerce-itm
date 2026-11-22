output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = aws_subnet.private[*].id
}

output "web_sg_id" {
  description = "Security Group de la capa web"
  value       = aws_security_group.web.id
}

output "db_sg_id" {
  description = "Security Group de la base relacional (RDS)"
  value       = aws_security_group.db.id
}

output "cache_sg_id" {
  description = "Security Group de la base en memoria (ElastiCache)"
  value       = aws_security_group.cache.id
}
