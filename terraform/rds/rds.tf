resource "aws_db_subnet_group" "this" {
  name       = "${var.app}-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets
  tags       = local.common_tags
  provider   = aws.landing-zone-account
}

resource "aws_db_instance" "this" {
  identifier     = "${var.app}-database"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true # AWS-managed KMS key; swap for kms_key_id when a CMK is required

  db_name  = var.db_name
  username = var.db_user
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.backup_retention_days
  backup_window             = "03:00-04:00"
  maintenance_window        = "Sun:04:00-Sun:05:00"
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.app}-${terraform.workspace}-final"
  copy_tags_to_snapshot     = true

  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags     = local.common_tags
  provider = aws.landing-zone-account
}
