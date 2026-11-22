# Estado remoto en S3.
# El bucket y la región NO se escriben aquí: el pipeline los entrega con
#   terraform init -backend-config="bucket=..." -backend-config="region=..."
# use_lockfile = true crea un archivo .tflock en S3 para bloquear ejecuciones
# simultáneas (no hace falta DynamoDB en Terraform >= 1.10).
terraform {
  backend "s3" {
    key          = "tienda/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
