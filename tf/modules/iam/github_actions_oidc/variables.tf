variable "region" {
  type        = string
  description = "AWS region for resources and ARNs."
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user name."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name."
}

variable "github_branches" {
  type        = list(string)
  description = "Allowed GitHub branches for role assumption."
  default     = ["main"]
}

variable "allowed_subjects" {
  type        = list(string)
  description = "Optional explicit OIDC subject claims. If null, derived from github_owner/github_repo/github_branches."
  default     = null
}

variable "create_oidc_provider" {
  type        = bool
  description = "Create the GitHub OIDC provider in this module."
  default     = true
}

variable "existing_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub OIDC provider ARN. Required when create_oidc_provider is false."
  default     = null
}

variable "role_name" {
  type        = string
  description = "IAM role name assumed by GitHub Actions."
  default     = "github-actions-batch-deploy-role"
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket name used for Terraform/Terragrunt state."
}

variable "tf_state_key_prefix" {
  type        = string
  description = "State object key prefix the role is allowed to access."
  default     = "dev"
}

variable "dynamodb_lock_table" {
  type        = string
  description = "Optional DynamoDB table name for Terraform state locks."
  default     = null
}
