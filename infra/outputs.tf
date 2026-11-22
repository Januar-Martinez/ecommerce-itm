output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Subredes públicas"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Subredes privadas"
  value       = module.networking.private_subnet_ids
}

output "db_endpoint" {
  description = "Host de la base MySQL (RDS)"
  value       = module.database.db_endpoint
}

output "cache_endpoint" {
  description = "Host del nodo Redis (ElastiCache)"
  value       = module.database.cache_endpoint
}

output "web_url" {
  description = "Dirección de la tienda"
  value       = "http://${module.compute.public_ip}"
}

output "instance_id" {
  description = "ID de la instancia EC2"
  value       = module.compute.instance_id
}

output "dashboard_url" {
  description = "Dashboard de CloudWatch de la tienda"
  value       = module.observability.dashboard_url
}

output "log_group" {
  description = "Grupo de logs del contenedor"
  value       = module.compute.log_group_name
}
