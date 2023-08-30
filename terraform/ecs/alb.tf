### load balancer

resource "aws_lb" "topflight-ifacing-alb" {
  name               = "${var.app}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [data.terraform_remote_state.network.outputs.public_subnets[0], data.terraform_remote_state.network.outputs.public_subnets[1]]
  tags               = local.common_tags
  provider           = aws.landing-zone-account
}

resource "aws_alb_target_group" "topflight-tg_alb" {
  name        = "${var.app}-alb-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.topflight-ifacing-alb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.topflight-ifacing-alb.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.alb_tls_cert_arn

  default_action {
    target_group_arn = aws_alb_target_group.topflight-tg_alb.id
    type             = "forward"
  }
  tags     = local.common_tags
  provider = aws.landing-zone-account
}

