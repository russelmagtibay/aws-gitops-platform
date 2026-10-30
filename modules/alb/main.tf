resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-alb"
  }
  lifecycle {
    precondition {
      condition     = length(distinct(var.public_subnet_ids)) >= 2
      error_message = "ALB must be deployed across at least 2 distinct public subnets for High Availability."
    }
  }
}

# 2. The Target Group (Routes traffic to Fargate IPs & checks /health)
resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = {
    Name = "${var.project_name}-tg"
  }
  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = var.container_port >= 1024
      error_message = "Target Group must forward to an unprivileged container port (>= 1024)."
    }
  }
}

# 3. The HTTP Listener (Listens on Port 80 and forwards to Target Group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

  