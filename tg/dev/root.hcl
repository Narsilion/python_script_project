locals {
  region           = "eu-central-1"
  tf_state_bucket  = "aartemov-tf-state"
  tf_state_region  = "eu-central-1"
}

remote_state {
  backend = "s3"
  config = {
    bucket  = local.tf_state_bucket
    key     = "dev/${path_relative_to_include()}/terraform.tfstate"
    region  = local.tf_state_region
    encrypt = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
}
EOF
}
