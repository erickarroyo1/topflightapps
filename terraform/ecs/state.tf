terraform {
  backend "s3" {
    bucket         = "terraform-topflightapp-tf-bucket-state"
    key            = "ecs/topflightapp/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-topflightapp-tf-state-lock"
    encrypt        = true
  }
}
