resource "aws_dynamodb_table" "terraform_state" {
  name         = "${var.app_name}-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags     = { Name = "${var.app_name}-state-lock" }
  provider = aws.landing-zone-account
}
