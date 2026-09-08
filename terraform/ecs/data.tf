data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-topflightapp-tf-bucket-state"
    key    = "env:/${terraform.workspace}/vpc/topflightapp/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = "terraform-topflightapp-tf-bucket-state"
    key    = "env:/${terraform.workspace}/rds/topflightapp/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {
  provider = aws.landing-zone-account
}
