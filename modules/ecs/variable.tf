variable "project_name" {
  description = "Prefix used to name ECS resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for CloudWatch logs"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format (e.g., ap-southeast-1)."
  }
}

variable "private_subnet_ids" {
  description = "Private subnets where Fargate tasks run"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2 && alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "At least 2 valid private subnet IDs ('subnet-...') are required for Multi-AZ High Availability."
  }
}

variable "ecs_tasks_sg_id" {
  description = "Security Group ID for ECS tasks"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.ecs_tasks_sg_id))
    error_message = "ecs_tasks_sg_id must be a valid AWS Security Group ID starting with 'sg-'."
  }
}

variable "target_group_arn" {
  description = "ALB Target Group ARN to register tasks with"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:elasticloadbalancing:", var.target_group_arn))
    error_message = "target_group_arn must be a valid AWS ALB Target Group ARN."
  }
}

variable "container_image" {
  description = "Docker image URI to run in ECS"
  type        = string
  default     = "public.ecr.aws/docker/library/python:3.12-slim"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port >= 1024 && var.container_port <= 65535
    error_message = "container_port must be an unprivileged port between 1024 and 65535."
  }
}