terraform {
  source = "../../../../tf/modules/iam/github_actions_oidc"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  github_owner = get_env("GITHUB_OWNER", "CHANGE_ME")
  github_repo  = get_env("GITHUB_REPO", "python_script_project")
}

inputs = {
  region              = include.root.locals.region
  github_owner        = local.github_owner
  github_repo         = local.github_repo
  github_branches     = ["main"]
  create_oidc_provider = true
  role_name           = "github-actions-batch-deploy-role"
  tf_state_bucket     = include.root.locals.tf_state_bucket
  tf_state_key_prefix = "dev"
}
