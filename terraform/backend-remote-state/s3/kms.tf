resource "aws_kms_key" "state" {
  description             = "Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = { Name = "${var.app_name}-state" }
  provider                = aws.landing-zone-account
}

resource "aws_kms_alias" "state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.state.key_id
  provider      = aws.landing-zone-account
}
