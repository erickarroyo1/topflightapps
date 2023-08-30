output "dynamodb_enpoint" {
  value = aws_dynamodb_table.terraform_state.name
}