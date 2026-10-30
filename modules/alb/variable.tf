variable "project_name" {
  description = "Prefix used to name ALB resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name)) && length(var.project_name) <= 24
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens (max 24 chars so ALB/TG names stay under AWS's 32-char limit)."
  }
}

variable "vpc_id" {
  description = "VPC ID for the Target Group"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID starting with 'vpc-'."
  }
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where the ALB lives (minimum 2 AZs required by AWS ALB)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2 && alltrue([for id in var.public_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "AWS Application Load Balancers require at least 2 valid public subnet IDs ('subnet-...') across different Availability Zones."
  }
}

variable "alb_sg_id" {
  description = "Security Group ID attached to the ALB"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.alb_sg_id))
    error_message = "alb_sg_id must be a valid AWS Security Group ID starting with 'sg-'."
  }
}

variable "container_port" {
  description = "Port on which containers receive traffic"
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port >= 1024 && var.container_port <= 65535
    error_message = "container_port must be an unprivileged port between 1024 and 65535."
  }
}