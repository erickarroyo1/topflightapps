locals {
  common_tags = {
    Terraform   = "true"
    Environment = terraform.workspace
    Owner       = "Erick Arroyo"
    Project     = "${var.app}-DevSecOps"
  }
}

variable "app" {}
variable "region" {}
variable "profile" {}

### Database Variables

variable "db_user" {}

variable "db_pass" {}

variable "db_name" {}


