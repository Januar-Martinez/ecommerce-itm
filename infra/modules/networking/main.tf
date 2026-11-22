# Módulo: networking
# Construye la red desde cero: VPC, subredes públicas y privadas,
# Internet Gateway, rutas y los Security Groups (firewalls).
# Nada de este módulo genera costo en AWS.

# Zonas de disponibilidad (data center independientes) de la región.
# RDS exige subredes en al menos 2 zonas, por eso usamos las 2 primeras.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# --- Red principal -----------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# Puerta de salida/entrada a internet de la VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# --- Subredes ----------------------------------------------------------------

# Públicas: aquí vive la EC2 con el contenedor. Una subred es "pública"
# porque su tabla de rutas tiene salida al Internet Gateway.
# cidrsubnet("10.0.0.0/16", 8, 0) = 10.0.0.0/24, índice 1 = 10.0.1.0/24
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${count.index + 1}"
  }
}

# Privadas: aquí viven RDS y ElastiCache. No tienen ruta a internet,
# así que nadie desde afuera puede llegar a las bases de datos.
# Índices 10 y 11 = 10.0.10.0/24 y 10.0.11.0/24
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name_prefix}-private-${count.index + 1}"
  }
}

# --- Rutas -------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Security Groups (firewalls encadenados) ---------------------------------

# Web: la tienda recibe HTTP desde cualquier lugar. No abrimos SSH:
# la administración se hará por AWS Systems Manager (Session Manager).
resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "HTTP publico hacia la tienda"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida libre (descargas, actualizaciones)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-web-sg"
  }
}

# Base relacional: solo acepta MySQL (3306) desde el Security Group web.
resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "MySQL solo desde la capa web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL desde web"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name = "${var.name_prefix}-db-sg"
  }
}

# Base en memoria: solo acepta Redis (6379) desde el Security Group web.
resource "aws_security_group" "cache" {
  name        = "${var.name_prefix}-cache-sg"
  description = "Redis solo desde la capa web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis desde web"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name = "${var.name_prefix}-cache-sg"
  }
}

# Cierra el Security Group por defecto de la VPC (sin reglas = sin tráfico).
# Así nada queda protegido por accidente con un grupo abierto.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-default-cerrado"
  }
}
