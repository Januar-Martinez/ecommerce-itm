terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Todos los recursos que Terraform cree llevarán esta etiqueta,
  # así es fácil encontrarlos (y borrarlos) en la consola.
  default_tags {
    tags = {
      Proyecto = "EcommerceContenedores"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  name_prefix = var.name_prefix
  vpc_cidr    = var.vpc_cidr
}

module "database" {
  source = "./modules/database"

  name_prefix        = var.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  db_sg_id           = module.networking.db_sg_id
  cache_sg_id        = module.networking.cache_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

module "compute" {
  source = "./modules/compute"

  name_prefix = var.name_prefix
  subnet_id   = module.networking.public_subnet_ids[0]
  web_sg_id   = module.networking.web_sg_id
  db_host     = module.database.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  cache_host  = module.database.cache_endpoint
}
