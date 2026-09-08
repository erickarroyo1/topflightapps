# Keyless CI: GitHub Actions assumes an IAM role via OIDC. No access keys are
# created, stored, or rotated. Two roles with different trust scopes:
#   plan  -> any branch / PR of this repo, read-only + state read
#   apply -> only the `prod` GitHub environment on this repo (gated by required reviewers)

data "aws_caller_identity" "current" {}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

locals {
  repo_sub = "repo:${var.github_org}/${var.github_repo}"

  # Every role this pipeline is allowed to touch is named after the repo.
  # Anything outside the prefix is out of reach for CI.
  owned_roles = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.github_repo}-*"
}

# ---- plan role: any ref in this repo, read-only --------------------------------
data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # Branches and pull requests of this repo, listed explicitly. A bare
    # `${local.repo_sub}:*` would also match every environment this repo grows
    # later, including `prod`, which is meant to be reachable only by the
    # apply role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "${local.repo_sub}:ref:refs/heads/*",
        "${local.repo_sub}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "${var.github_repo}-gha-plan"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

# `ReadOnlyAccess` is account-wide and grows whenever AWS adds services to it.
# A plan only needs to read the resources these six stacks manage.
data "aws_iam_policy_document" "plan_permissions" {
  statement {
    sid = "DescribeManagedStack"
    actions = [
      "ec2:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "elasticloadbalancing:Describe*",
      "rds:Describe*",
      "rds:ListTagsForResource",
      "logs:Describe*",
      "logs:ListTagsForResource",
      "application-autoscaling:Describe*",
      "cloudwatch:Describe*",
      "cloudwatch:ListTagsForResource",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "s3:GetBucket*",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:ListTagsOfResource",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:GetOpenIDConnectProvider",
    ]
    resources = ["*"]
  }

  statement {
    sid = "SecretMetadata"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:GetResourcePolicy",
    ]
    resources = ["*"]
  }

  # Refreshing `aws_secretsmanager_secret_version` during a plan reads the value,
  # so the plan role needs it — but only for this application's own secrets, not
  # for everything the account holds.
  statement {
    sid       = "ReadOwnSecretValues"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.app}/*"]
  }
}

resource "aws_iam_role_policy" "plan_permissions" {
  name   = "infra-plan"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_permissions.json
}

# ---- apply role: only the protected `prod` environment ------------------------
data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.repo_sub}:environment:prod"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name                 = "${var.github_repo}-gha-apply"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
}

# Scoped to the services this repo manages. Not AdministratorAccess, and not a
# path to it either: role creation is confined to the repo's name prefix and
# gated on the workload permissions boundary (see boundary.tf), and PassRole is
# limited to the two services this stack runs.
data "aws_iam_policy_document" "apply_permissions" {
  statement {
    sid = "Infra"
    actions = [
      "ec2:*", "ecs:*", "elasticloadbalancing:*", "rds:*", "logs:*",
      "secretsmanager:*", "application-autoscaling:*", "cloudwatch:*"
    ]
    resources = ["*"]
  }
  # Reading a role, tagging it, or taking permissions away from it carries no
  # escalation risk, so these need no boundary condition. All of them are still
  # confined to roles named after this repo.
  statement {
    sid = "IamRoleReadAndRevoke"
    actions = [
      "iam:GetRole", "iam:GetRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
      "iam:TagRole", "iam:UntagRole", "iam:UpdateRole",
      "iam:DeleteRole", "iam:DetachRolePolicy", "iam:DeleteRolePolicy",
    ]
    resources = [local.owned_roles]
  }

  # Creating a role or granting it permissions is allowed only while the role
  # carries the workload boundary. This is the condition that stops
  # CreateRole + AttachRolePolicy(AdministratorAccess) from becoming account admin.
  statement {
    sid = "IamRoleWriteRequiresBoundary"
    actions = [
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
    ]
    resources = [local.owned_roles]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.workload_boundary.arn]
    }
  }

  # A role can only be handed to the two services this stack actually runs.
  statement {
    sid       = "IamPassRoleToStackServicesOnly"
    actions   = ["iam:PassRole"]
    resources = [local.owned_roles]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
    }
  }

  # Service-linked roles live under a reserved path and are shaped by AWS, not
  # by this pipeline, so a boundary does not apply to them.
  statement {
    sid       = "IamServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/*"]
  }
  statement {
    sid       = "IamRead"
    actions   = ["iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListPolicyVersions"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "apply_permissions" {
  name   = "infra-apply"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_permissions.json
}

# ---- state access, shared by both roles ---------------------------------------
data "aws_iam_policy_document" "state_access" {
  statement {
    actions   = ["s3:ListBucket", "s3:GetBucketVersioning"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*"]
  }
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = ["arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table}"]
  }
  statement {
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.state_access.json
}

resource "aws_iam_role_policy" "apply_state" {
  name   = "terraform-state"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.state_access.json
}
