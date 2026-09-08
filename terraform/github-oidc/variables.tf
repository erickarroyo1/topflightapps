variable "region" {
  type    = string
  default = "us-east-1"
}

variable "github_org" {
  description = "GitHub user or organization that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "Repository name (without org)"
  type        = string
}

variable "state_bucket" {
  description = "Terraform state bucket name"
  type        = string
}

variable "lock_table" {
  description = "Terraform lock table name"
  type        = string
}
