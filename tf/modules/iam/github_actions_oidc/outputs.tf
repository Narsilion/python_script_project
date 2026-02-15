output "role_arn" {
  description = "IAM role ARN for GitHub Actions."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "IAM role name for GitHub Actions."
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN used by the GitHub Actions role."
  value       = local.oidc_provider_arn
}

output "allowed_subjects" {
  description = "Allowed OIDC subject claims configured in trust policy."
  value       = local.allowed_subjects
}
