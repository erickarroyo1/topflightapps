output "endpoint_rds" {
  description = "RDS hostname (no port)"
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the master credentials. Consumers read the secret at runtime; the password is never exposed as an output."
  value       = aws_secretsmanager_secret.db.arn
}

output "rds_sg_id" {
  description = "RDS security group ID, used by consumers to scope their egress"
  value       = aws_security_group.rds_sg.id
}
