# BOOTSTRAP (se ejecuta UNA vez, a mano, desde tu computador)
# Crea lo que el pipeline necesita antes de poder correr:
#   1. Bucket S3 para el estado remoto de Terraform
#   2. Proveedor OIDC de GitHub (GitHub se autentica en AWS sin claves guardadas)
#   3. Rol "plan"  -> solo lectura, lo usan los pull requests
#   4. Rol "apply" -> crea infraestructura, solo lo usa el entorno "production"
#      (que exige aprobación manual) de TU repositorio.

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

  default_tags {
    tags = {
      Proyecto = "EcommerceContenedores"
      Origen   = "bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "tienda-tfstate-${data.aws_caller_identity.current.account_id}"

  # GitHub declara la identidad con los IDs numéricos del dueño y del repositorio:
  #   repo:USUARIO@ID_USUARIO/REPO@ID_REPO:<evento>
  # Exigir los IDs impide que otro repositorio con el mismo nombre use estos roles.
  repo_owner = split("/", var.github_repo)[0]
  repo_name  = split("/", var.github_repo)[1]
  github_sub = "repo:${local.repo_owner}@${var.github_owner_id}/${local.repo_name}@${var.github_repo_id}"
}

# --- 1. Bucket de estado ------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = true # laboratorio: permite borrarlo al final con terraform destroy
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 2. OIDC de GitHub --------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# --- 3. Rol de solo lectura para "plan" (pull requests) ----------------------
resource "aws_iam_role" "plan" {
  name = "tienda-github-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "${local.github_sub}:pull_request"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# --- 4. Rol de "apply" (solo el entorno production del repositorio) ----------
resource "aws_iam_role" "apply" {
  name = "tienda-github-apply"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "${local.github_sub}:environment:production"
        }
      }
    }]
  })
}

# Laboratorio: AdministratorAccess para simplificar. En producción se reemplaza
# por una política de mínimo privilegio con solo los servicios que usa Terraform.
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
