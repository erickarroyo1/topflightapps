Harden baseline: secrets, RDS, network, IAM, keyless CI

Revisited this 2023 assessment with a security review. Every change below is something I would flag in a real client's Terraform.

**Secrets.** DB password was a Terraform variable ending up as a plain env var in the task definition. Now `random_password` → Secrets Manager → ECS `secrets`/`valueFrom`. Removed `db_pass` from every variables file.

**RDS.** MySQL 5.7 → 8.0. Added `storage_encrypted`, backups, final snapshot, `deletion_protection`, log exports. Removed egress from the RDS SG (it never initiates connections).

**Network.** ECS ingress now from the ALB SG only. ECS egress restricted to 443 and 3306→RDS SG. ALB egress only to tasks. Flow logs on the VPC.

**IAM.** Split execution role and task role. `aws:SourceAccount` on trust policy. Replaced deprecated `managed_policy_arns`.

**CI/CD (new).** GitHub Actions with OIDC, two roles (plan: any ref, read-only; apply: `prod` environment only, scoped writes). PR runs fmt, validate, trivy, plan-as-comment, and fails on any plan that deletes `aws_db_instance`/`aws_s3_bucket`/`aws_secretsmanager_secret`. Apply only from `main` after environment approval.

**State.** KMS CMK with rotation, public access block, TLS-only policy, on-demand lock table with PITR.

**Removed.** Bastion user-data with hardcoded DB users. Flask `debug=True`.

Validated: `terraform validate` on all six stacks, `trivy config` HIGH/CRITICAL clean (two findings suppressed inline with justification: public ALB by design, 443 egress pending VPC endpoints).
