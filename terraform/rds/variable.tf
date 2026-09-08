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

variable "db_user" {
  description = "Master username. The password is generated and stored in Secrets Manager, never passed as a variable."
  type        = string
  default     = "admin"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Enable Multi-AZ. Set true for production."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}
