# Ingress only from the private subnets (where ECS tasks run). No egress needed:
# RDS never initiates outbound connections.
resource "aws_security_group" "rds_sg" {
  name        = "${var.app}-rds-sg"
  description = "RDS ingress from private subnets only"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc

  ingress {
    cidr_blocks = data.terraform_remote_state.network.outputs.private_subnets_cidr_blocks
    description = "MySQL from private subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}
