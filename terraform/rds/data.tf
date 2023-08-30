data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "terraform-topflightapp-tf-bucket-state"
    key     = "env:/${terraform.workspace}/vpc/topflightapp/terraform.tfstate"
    region  = "us-east-1"
    profile = "tlz-account"
  }
}