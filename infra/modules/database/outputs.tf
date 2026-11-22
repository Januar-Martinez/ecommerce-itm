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
