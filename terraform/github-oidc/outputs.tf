output "plan_role_arn" {
  description = "Set as repository variable AWS_PLAN_ROLE_ARN"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Set as environment (prod) variable AWS_APPLY_ROLE_ARN"
  value       = aws_iam_role.apply.arn
}
