provider "aws" {
  region  = var.region
  profile = var.profile
  alias   = "landing-zone-account"
}