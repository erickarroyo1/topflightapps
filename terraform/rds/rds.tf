resource "aws_db_subnet_group" "topflight-rds-subnet-group" {
  name       = "topflightapps-subnet-group"
  subnet_ids = [data.terraform_remote_state.network.outputs.private_subnets[0], data.terraform_remote_state.network.outputs.private_subnets[1]]
  provider   = aws.landing-zone-account
}

resource "aws_db_instance" "topflight-rds-instance" {
  identifier             = "topflightapps-database"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_pass
  skip_final_snapshot    = true
  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
  db_subnet_group_name   = aws_db_subnet_group.topflight-rds-subnet-group.name
  instance_class         = var.instance_class

  tags     = local.common_tags
  provider = aws.landing-zone-account
}


