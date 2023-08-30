### security group for ECS
resource "aws_security_group" "ecs_sg" {
  name   = "${var.app}-ecs-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc

  ingress {
    cidr_blocks = data.terraform_remote_state.network.outputs.private_subnets_cidr_blocks
    description = "Access to port 8080 for container topfligthapps"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "All trafic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags     = local.common_tags
  provider = aws.landing-zone-account
}

