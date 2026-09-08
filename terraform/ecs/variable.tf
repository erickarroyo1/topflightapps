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

variable "container_image" {
  description = "Container image (registry/repo:tag). Pin a digest in production."
  type        = string
}

variable "db_name" {
  description = "Database name passed to the app as plain env var (not sensitive)"
  type        = string
}

variable "alb_tls_cert_arn" {
  description = "ACM certificate ARN for the HTTPS listener"
  type        = string
}

variable "desired_count" {
  description = "Number of tasks"
  type        = number
  default     = 2
}
