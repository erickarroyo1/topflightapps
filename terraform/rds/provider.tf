terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Locally: export AWS_PROFILE=<sso-profile>. In CI: credentials come from the
# GitHub OIDC role (see terraform/github-oidc). No static keys anywhere.
provider "aws" {
  region = var.region
  alias  = "landing-zone-account"
}

provider "random" {}
