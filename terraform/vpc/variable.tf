locals {
  common_tags = {
    Terraform   = "true"
    Environment = terraform.workspace
    Owner       = "Erick Arroyo"
    Project     = "${var.app}-DevSecOps"
  }
}

variable "app" {
  description = "Application name used as prefix for all resources"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
