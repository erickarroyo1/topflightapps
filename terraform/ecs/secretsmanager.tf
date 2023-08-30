resource "aws_secretsmanager_secret" "topflightapp_db_password_secret" {
  name     = "topflightapp-db-password"
  provider = aws.landing-zone-account
}

resource "aws_secretsmanager_secret_version" "topflightapp_db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.topflightapp_db_password_secret.id
  secret_string = var.db_pass
  provider      = aws.landing-zone-account
}
