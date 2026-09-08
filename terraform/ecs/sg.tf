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

# The ALB's rules are standalone resources rather than inline blocks. Its egress
# has to point at the ECS security group, and `ecs_sg` already points back at
# this one, so keeping both inline would make the two resources depend on each
# other and Terraform would refuse the graph. Splitting the rules out breaks the
# cycle. Inline and standalone rules must not be mixed on the same group, so all
# of this group's rules live out here; `ecs_sg` above keeps its inline blocks.
# Terraform drops the AWS default allow-all egress when it creates the group.
resource "aws_security_group" "alb_sg" {
  name        = "${var.app}-alb-sg"
  description = "Public ALB: 80 (redirect) and 443"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_v4" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "HTTP, redirected to HTTPS"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
  provider          = aws.landing-zone-account
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_v6" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "HTTP, redirected to HTTPS"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv6         = "::/0"
  tags              = local.common_tags
  provider          = aws.landing-zone-account
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_v4" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
  provider          = aws.landing-zone-account
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_v6" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv6         = "::/0"
  tags              = local.common_tags
  provider          = aws.landing-zone-account
}

# Reaches the tasks by security group, not by subnet CIDR: anything else sharing
# those subnets is not a valid destination.
resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb_sg.id
  description                  = "To ECS tasks only"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.ecs_sg.id
  tags                         = local.common_tags
  provider                     = aws.landing-zone-account
}
