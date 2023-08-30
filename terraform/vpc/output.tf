output "vpc" {
  description = "Vpc ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "private_subnets"
  value       = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "private_subnets_cidr_blocks"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "public_subnets"
  value       = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "public_subnets_cidr_blocks"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "nat_public_ips" {
  description = "nat_public_ips"
  value       = module.vpc.nat_public_ips
}

output "azs" {
  description = "azs"
  value       = module.vpc.azs
}








