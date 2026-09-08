terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# Bootstrap is run once, locally, with an SSO profile (export AWS_PROFILE=...).
provider "aws" {
  region = var.region
  alias  = "landing-zone-account"
}
