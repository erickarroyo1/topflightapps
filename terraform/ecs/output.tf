output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = aws_lb.this.dns_name
}
