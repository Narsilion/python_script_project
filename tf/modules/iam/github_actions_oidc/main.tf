data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "tls_certificate" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_thumbprint = data.tls_certificate.github_oidc.certificates[length(data.tls_certificate.github_oidc.certificates) - 1].sha1_fingerprint

  allowed_subjects = var.allowed_subjects != null ? var.allowed_subjects : [
    for branch in var.github_branches : "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${branch}"
  ]
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.github_thumbprint]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  lifecycle {
    precondition {
      condition     = var.create_oidc_provider || var.existing_oidc_provider_arn != null
      error_message = "existing_oidc_provider_arn must be set when create_oidc_provider is false."
    }
  }
}

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid = "BatchAndInfraManagement"
    actions = [
      "batch:*",
      "ec2:Describe*",
      "ecs:CreateCluster",
      "ecs:DescribeClusters",
      "ecs:RegisterContainerInstance",
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:CreateServiceLinkedRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "logs:*",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }

  statement {
    sid = "PassRoleToBatchAndEcsTasks"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "batch.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }

  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:CreateRepository",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["*"]
  }

  statement {
    sid = "TerraformStateBucket"
    actions = [
      "s3:GetBucketAcl",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketVersioning",
      "s3:PutBucketEncryption",
      "s3:PutBucketPolicy",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketVersioning",
      "s3:ListBucket"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket}"
    ]
  }

  statement {
    sid = "TerraformStateObjects"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket}/${var.tf_state_key_prefix}/*"
    ]
  }

  dynamic "statement" {
    for_each = var.dynamodb_lock_table != null ? [1] : []

    content {
      sid = "TerraformLockTable"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_lock_table}"
      ]
    }
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
