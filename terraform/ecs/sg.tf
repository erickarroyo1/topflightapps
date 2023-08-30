### security group for ECS
resource "aws_security_group" "ecs_sg" {
  name   = "${var.app}-ecs-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc

  ingress {
    cidr_blocks = [data.terraform_remote_state.network.outputs.private_subnets_cidr_blocks[0], data.terraform_remote_state.network.outputs.private_subnets_cidr_blocks[1], data.terraform_remote_state.network.outputs.public_subnets_cidr_blocks[0], data.terraform_remote_state.network.outputs.public_subnets_cidr_blocks[1]]
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



resource "aws_security_group" "alb-sg" {
  name   = "${var.app}-alb-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags     = local.common_tags
  provider = aws.landing-zone-account
}