# 1. ECS Cluster with Container Insights enabled
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# 2. CloudWatch Log Group (14-day retention to stay Free-Tier friendly)
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-api"
  retention_in_days = 14
}

# 3. IAM Role Trust Policy for ECS Tasks
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# 4. Execution Role (used by ECS agent to pull ECR images and write logs)
resource "aws_iam_role" "execution" {
  name               = "${var.project_name}-app-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "execution_standard" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 5. Task Role (used by your Python app code itself if it calls AWS APIs)
resource "aws_iam_role" "task" {
  name               = "${var.project_name}-app-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# 6. ECS Task Definition (256 CPU = 0.25 vCPU, 512 MB RAM)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.container_image
      essential = true
      # Placeholder server: writes a "health" file and serves it on port 8000, so the
      # ALB health check (/health -> 200) passes before the real FastAPI image exists.
      # Pipeline 2 (Phase 5) removes this command when it deploys the real image.
      command = [
        "sh", "-c",
        "mkdir -p /srv && echo ok > /srv/health && cd /srv && python -m http.server 8000"
      ]
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 7. ECS Service (runs 2 tasks across 2 Availability Zones in Private Subnets)
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api"
    container_port   = var.container_port
  }

  # Automatically detect failed deployments and roll back to the last working version!
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Allow Pipeline 2 (app.yml) to update the task definition image without Terraform reverting it
  lifecycle {
    ignore_changes = [task_definition]

    precondition {
      condition     = length(distinct(var.private_subnet_ids)) >= 2
      error_message = "ECS Service must run across at least 2 distinct private subnets for High Availability."
    }
  }
}

# 8. Application Auto-Scaling (Scale between 2 and 4 tasks at 70% CPU)
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}