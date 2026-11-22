# E-commerce en AWS con Terraform, contenedores, bases gestionadas y CI/CD

Proyecto de la asignatura *Introducción a Modelos de Informática en la Nube* (ITM).

## Arquitectura
- **Red (VPC):** 2 subredes públicas, 2 privadas, Internet Gateway y Security Groups encadenados.
- **Bases de datos gestionadas:** Amazon RDS MySQL 8.4 (relacional) y Amazon ElastiCache Redis 7.1 (en memoria).
- **Contenedores:** EC2 t3.micro con Docker ejecutando una tienda Flask (`app/`).
- **CI/CD de la infraestructura:** GitHub Actions (`.github/workflows/`).

## Estructura
| Carpeta | Contenido |
|---|---|
| `bootstrap/` | Se ejecuta una sola vez a mano: bucket S3 de estado, OIDC de GitHub y roles |
| `infra/` | Terraform de la tienda (módulos `networking`, `database`, `compute`) |
| `app/` | Aplicación Flask y su Dockerfile |
| `.github/workflows/` | `terraform.yml` (CI/CD) y `destroy.yml` (destrucción manual) |

## Flujo del pipeline
1. **Pull request:** `fmt` → `validate` → Checkov (seguridad) → `plan` comentado en el PR. No crea nada.
2. **Merge a `main`:** mismas validaciones → **aprobación manual** (entorno `production`) → `apply`.
3. **Destroy:** Actions → *Terraform Destroy (manual)* → escribir `DESTRUIR`.

## Configuración requerida en GitHub
- Secret: `TF_VAR_db_password`
- Variables: `AWS_REGION`, `TF_STATE_BUCKET`, `AWS_PLAN_ROLE_ARN`, `AWS_APPLY_ROLE_ARN`, `ALERT_EMAIL`
- Entorno `production` con revisores requeridos.
