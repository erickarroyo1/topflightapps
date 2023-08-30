resource "aws_dynamodb_table" "terraform_state" {
  name           = "${var.app_name}-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  provider = aws.landing-zone-account

}