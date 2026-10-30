# 1. ALB Security Group: Allow HTTP (port 80) from allowed CIDRs
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP traffic to the Application Load Balancer"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.project_name}-alb-sg"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_vpc_security_group_ingress_rule" "alb" {
  for_each = var.alb_ingress_cidrs

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP on port 80 from ${each.key}"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow outbound traffic from ALB"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
# 2. ECS Tasks Security Group: ONLY allow traffic on container_port from the ALB SG!
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allow inbound traffic to ECS containers ONLY from the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = aws_security_group.alb.vpc_id == var.vpc_id
      error_message = "The ECS Security Group and ALB Security Group must belong to the exact same VPC."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Allow traffic on container port strictly from ALB SG"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  lifecycle {
    precondition {
      condition     = var.container_port >= 1024 && var.container_port != 80
      error_message = "ECS containers must run as non-root on an unprivileged port (>= 1024)."
    }
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs_all_out" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow outbound HTTPS/HTTP for pulling ECR images and updates"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}