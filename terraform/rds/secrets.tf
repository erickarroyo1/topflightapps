# The DB password is generated here and only ever lives in Secrets Manager
# (and, unavoidably, in the encrypted Terraform state). It is never a variable,
# never in tfvars, never in an environment variable of the task definition.

resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.app}/${terraform.workspace}/rds/master"
  description             = "RDS master credentials for ${var.app} (${terraform.workspace})"
  recovery_window_in_days = 7
  tags                    = local.common_tags
  provider                = aws.landing-zone-account
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_user
    password = random_password.db.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
  provider = aws.landing-zone-account
}
