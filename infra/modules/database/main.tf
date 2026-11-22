# Módulo: database
# Crea las dos bases de datos GESTIONADAS de la tienda:
#   - Amazon RDS (MySQL)       -> relacional: productos, usuarios, pedidos
#   - Amazon ElastiCache (Redis) -> en memoria: carrito de compras y sesiones
# "Gestionada" significa que AWS se encarga de instalar, parchar y
# mantener el motor; nosotros solo la usamos.
# OJO: estos recursos cobran por hora de existencia (centavos), así que
# se destruyen con "terraform destroy" al terminar.

# --- Base relacional: Amazon RDS (MySQL) --------------------------------------

# RDS exige un "grupo de subredes" con subredes en al menos 2 zonas.
# Usamos las privadas: la base nunca queda expuesta a internet.
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnets"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.name_prefix}-mysql"

  engine = "mysql"
  # 8.4 (LTS). MySQL 8.0 ya perdió el soporte estándar de RDS (31/07/2026)
  # y cobra recargo "Extended Support", por eso no lo usamos.
  engine_version = "8.4"
  instance_class = "db.t3.micro" # tamaño más pequeño, elegible para plan gratuito

  allocated_storage = 20 # GB, el mínimo
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false # solo accesible desde dentro de la VPC

  storage_encrypted                   = true # cifrado en reposo
  auto_minor_version_upgrade          = true # parches menores automáticos
  copy_tags_to_snapshot               = true
  iam_database_authentication_enabled = true
  multi_az                            = false # Multi-AZ duplicaría el costo

  # Configuración pensada para laboratorio (fácil de destruir y sin extras):
  backup_retention_period = 0    # sin copias automáticas
  skip_final_snapshot     = true # al destruir, no pide guardar una copia final
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = "${var.name_prefix}-mysql"
  }
}

# --- Base en memoria: Amazon ElastiCache (Redis) -----------------------------

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-cache-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id = "${var.name_prefix}-redis"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro" # nodo más pequeño
  num_cache_nodes      = 1                # un solo nodo, sin réplicas
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.cache_sg_id]
  apply_immediately  = true

  tags = {
    Name = "${var.name_prefix}-redis"
  }
}
