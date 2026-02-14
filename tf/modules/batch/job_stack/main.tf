locals {
  log_group_name = var.log_group_name != null ? var.log_group_name : "/aws/batch/job/${var.name}"
  subnet_ids     = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default.ids
  security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [
    data.aws_security_group.by_name.id
  ]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "by_name" {
  name   = var.security_group_name
  vpc_id = data.aws_vpc.default.id
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "batch_service" {
  name = "${var.name}-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service" {
  role       = aws_iam_role.batch_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role" "task_execution" {
  name = "${var.name}-batch-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_batch_compute_environment" "this" {
  name         = "${var.name}-ce"
  service_role = aws_iam_role.batch_service.arn
  type         = "MANAGED"
  state        = "ENABLED"

  compute_resources {
    max_vcpus = var.max_vcpus
    type      = var.compute_resource_type

    subnets            = local.subnet_ids
    security_group_ids = local.security_group_ids
  }

  depends_on = [aws_iam_role_policy_attachment.batch_service]
}

resource "aws_batch_job_queue" "this" {
  name     = "${var.name}-jq"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.this.arn
  }
}

resource "aws_batch_job_definition" "this" {
  name                  = "${var.name}-jd"
  type                  = "container"
  platform_capabilities = ["FARGATE"]
  propagate_tags        = true

  container_properties = jsonencode({
    image            = var.image
    command          = var.command
    executionRoleArn = aws_iam_role.task_execution.arn
    jobRoleArn       = aws_iam_role.task_execution.arn

    resourceRequirements = [
      {
        type  = "VCPU"
        value = tostring(var.vcpu)
      },
      {
        type  = "MEMORY"
        value = tostring(var.memory)
      }
    ]

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    networkConfiguration = {
      assignPublicIp = var.assign_public_ip ? "ENABLED" : "DISABLED"
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "batch"
      }
    }
  })
}
