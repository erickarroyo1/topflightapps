# Internet-facing by design: this is the public entry point. Protection layer
# (WAF, rate limiting) sits in front of it; see README "next steps".
#trivy:ignore:AVD-AWS-0053
resource "aws_lb" "this" {
  name                       = "${var.app}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = data.terraform_remote_state.network.outputs.public_subnets
  drop_invalid_header_fields = true
  enable_deletion_protection = true
  tags                       = local.common_tags
  provider                   = aws.landing-zone-account
}

resource "aws_lb_target_group" "this" {
  name        = "${var.app}-alb-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 3
    path                = "/"
    unhealthy_threshold = 2
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_tls_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}
