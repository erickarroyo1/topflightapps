# Permissions boundary that every role the CI apply role creates must carry.
#
# Why this exists: `iam:CreateRole` + `iam:AttachRolePolicy`, even restricted to a
# name prefix, is still a path to account admin — create a role, attach
# AdministratorAccess, pass it to a service the pipeline is already allowed to
# call. Requiring this boundary on create/attach/put caps what any such role can
# ever do. The apply role is deliberately not granted
# `iam:PutRolePermissionsBoundary` or `iam:DeleteRolePermissionsBoundary`, so it
# cannot lift the cap once it is set, and it is not granted
# `iam:CreatePolicyVersion` or `iam:SetDefaultPolicyVersion`, so it cannot widen
# the boundary itself.

data "aws_iam_policy_document" "workload_boundary" {
  statement {
    sid = "WorkloadRuntimeCeiling"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
  }

  # A workload role never needs to touch identity, billing or the org tree.
  # Denying it here means it stays true even if a future policy grants it.
  statement {
    sid    = "NeverIdentityOrOrg"
    effect = "Deny"
    actions = [
      "iam:*",
      "organizations:*",
      "account:*",
      "sts:AssumeRole",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "workload_boundary" {
  name        = "${var.github_repo}-workload-boundary"
  description = "Ceiling for every role created by the CI apply role. Cannot be removed or widened by CI."
  policy      = data.aws_iam_policy_document.workload_boundary.json
}
