terraform {
  source = "../../../../tf/modules/batch/job_stack"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  service_name = "python-script"

  image = "436081123286.dkr.ecr.eu-central-1.amazonaws.com/python-script:v1.0"

  vcpu   = 0.25
  memory = 512

  log_group = "/aws/batch/job/${local.service_name}"
}

inputs = {
  name                  = local.service_name
  region                = include.root.locals.region
  image                 = local.image
  vcpu                  = local.vcpu
  memory                = local.memory
  max_vcpus             = 8
  compute_resource_type = "FARGATE_SPOT"
  log_group_name        = local.log_group
  security_group_name   = "default"

  command = [
    "python",
    "/app/main.py"
  ]
}
