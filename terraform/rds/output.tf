output "endpoint_rds" {
  description = "endpoint RDS"
  value       = split(":", aws_db_instance.topflight-rds-instance.endpoint)[0] #Split to avoid get the port by default
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.topflight-rds-instance.address
  sensitive   = false
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.topflight-rds-instance.port
  sensitive   = false
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.topflight-rds-instance.username
  sensitive   = true
}