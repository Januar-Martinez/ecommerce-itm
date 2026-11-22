output "state_bucket" {
  description = "Bucket del estado remoto (variable TF_STATE_BUCKET en GitHub)"
  value       = aws_s3_bucket.state.id
}

output "plan_role_arn" {
  description = "Rol de plan (variable AWS_PLAN_ROLE_ARN en GitHub)"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Rol de apply (variable AWS_APPLY_ROLE_ARN en GitHub)"
  value       = aws_iam_role.apply.arn
}
