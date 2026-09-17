output "secret_arn" {
  description = "ARN of the credentials secret. Sourced from the version resource so dependents wait until the value is written."
  value       = aws_secretsmanager_secret_version.this.secret_arn
}

output "secret_name" {
  description = "Name of the credentials secret."
  value       = aws_secretsmanager_secret.this.name
}

output "read_policy_arn" {
  description = "ARN of the optional read policy, or null."
  value       = var.create_read_policy ? aws_iam_policy.read[0].arn : null
}
