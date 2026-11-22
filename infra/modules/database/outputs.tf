output "db_endpoint" {
  description = "Dirección (host) de la base MySQL en RDS"
  value       = aws_db_instance.mysql.address
}

output "db_port" {
  description = "Puerto de MySQL"
  value       = aws_db_instance.mysql.port
}

output "cache_endpoint" {
  description = "Dirección (host) del nodo Redis en ElastiCache"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "cache_port" {
  description = "Puerto de Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "db_identifier" {
  description = "Identificador de la instancia RDS (para alarmas de CloudWatch)"
  value       = aws_db_instance.mysql.identifier
}

output "cache_cluster_id" {
  description = "ID del clúster Redis (para alarmas de CloudWatch)"
  value       = aws_elasticache_cluster.redis.cluster_id
}
