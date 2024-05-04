resource "aws_lb" "app" {
  name               = "${local.prefix}-main"
  load_balancer_type = "application"
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  timeouts {
    create = "30m"
    delete = "30m"
  }

  security_groups = [aws_security_group.lb.id]

  tags = local.common_tags
}

# The app (Target) to which the load balancer will send requests to #
resource "aws_lb_target_group" "app" {
  name        = "${local.prefix}-app"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  port        = 3000

  health_check {
    path = "/login/"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
}

# Listens to request (entry point) and sends request to the app #
# Redirects to https if initial request is http #
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
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
}

resource "aws_lb_listener" "app_https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


resource "aws_security_group" "lb" {
  description = "Allow access to Application Load Balancer"
  name        = "${local.prefix}-lb"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# For assigning sticky policy on load balancer #
/*
resource "aws_lb_cookie_stickiness_policy" "app" {
  name                     = "${local.prefix}-lb-stick-pol"
  load_balancer            = aws_lb.app.id
  lb_port                  = 80
  cookie_expiration_period = 600
}
*/