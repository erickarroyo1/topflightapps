# ECS tasks accept traffic only from the ALB security group, not from CIDRs.
resource "aws_security_group" "ecs_sg" {
  name        = "${var.app}-ecs-sg"
  description = "ECS tasks: ingress from ALB only, egress restricted"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc

  ingress {
    security_groups = [aws_security_group.alb_sg.id]
    description     = "App port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
  }

  # HTTPS out through NAT: ECR pull, Secrets Manager, CloudWatch Logs.
  # Next step to remove this entirely: VPC endpoints for ecr.api, ecr.dkr, s3,
  # secretsmanager and logs, then egress only to the endpoint SG.
  #trivy:ignore:AVD-AWS-0104
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to AWS APIs via NAT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  egress {
    security_groups = [data.terraform_remote_state.rds.outputs.rds_sg_id]
    description     = "MySQL to RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.app}-alb-sg"
  description = "Public ALB: 80 (redirect) and 443"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc

  ingress {
    description      = "HTTP, redirected to HTTPS"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "To ECS tasks only"
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = data.terraform_remote_state.network.outputs.private_subnets_cidr_blocks
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}
