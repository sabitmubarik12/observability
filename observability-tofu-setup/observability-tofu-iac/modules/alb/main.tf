
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description   = "Allow HTTP from anywhere"
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  ingress {
    description   = "Allow HTTPS from anywhere"
    from_port     = 443
    to_port       = 443
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }


  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_lb" "observability_alb" {
  name               = "${var.environment}-observability-alb"
  load_balancer_type = "application"
  # 'var.public_subnets' is now a list of subnets, each in a unique AZ
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${var.environment}-observability-alb"
  }
}


resource "aws_lb_target_group" "observability_tg" {
  name     = "${var.environment}-observability-tg"
  port     = var.observability_target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = "traffic-port"
    protocol            = "HTTP"
    path                = "/healthcheck.txt"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "${var.environment}-observability-tg"
  }
}

# Grafana Target Group
resource "aws_lb_target_group" "grafana_tg" {
  name     = "tg-grafana"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "Grafana Target Group"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.observability_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.observability_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.observability_tg.arn
  }
}

# Grafana Listener Rule
resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }

  condition {
    path_pattern {
      values = ["/grafana/*"]
    }
  }
}

locals {
  # Create a map with static keys for each expected instance.
  # For a single instance, we use a fixed key.
  observability_instances_map = {
    for idx, id in var.observability_instance_ids :
    "instance-${idx}" => id
  }
}

resource "aws_lb_target_group_attachment" "observability_attachments" {
  for_each = local.observability_instances_map

  target_group_arn = aws_lb_target_group.observability_tg.arn
  target_id        = each.value
  port             = var.observability_target_port
}

resource "aws_lb_target_group_attachment" "grafana_attachment" {
  for_each = local.observability_instances_map
  target_id        = each.value
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  port             = 3000
}