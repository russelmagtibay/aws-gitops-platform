# Input 1: Project prefix for naming alarms and topics

variable "project_name" {
  description = "Prefix used to name monitoring resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens."
  }
}

# Input 2: Comes from module.ecs.cluster_name so CloudWatch knows WHICH cluster to watch

variable "cluster_name" {
  description = "ECS cluster name to monitor"
  type        = string

  validation {
    # trimspace() removes spaces so someone cannot pass "   " as a fake name
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name must not be empty."

  }

}

# Input 3: Comes from module.ecs.service_name so CloudWatch knows WHICH service to watch

variable "service_name" {
  description = "ECS service name to monitor"
  type        = string

  validation {
    condition     = length(trimspace(var.service_name)) > 0
    error_message = "service_name must not be empty."
  }
}

# Input 4: Comes from module.alb.alb_arn_suffix (CloudWatch uses the short suffix, not the full ARN!)
variable "alb_arn_suffix" {
  description = "ALB ARN suffix for HTTP 5xx metrics"
  type        = string
  validation {
    condition     = can(regex("^app/", var.alb_arn_suffix))
    error_message = "alb_arn_suffix must be a valid Application Load Balancer ARN suffix starting with 'app/'."
  }
}

# Input 5: Your email address where AWS will send alarm & budget notifications
variable "alert_email" {
  description = "Email address to receive CloudWatch and Budget alerts"
  type        = string
  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

# Input 6: Your monthly budget cap in USD ($10 default)
variable "monthly_budget_usd" {
  description = "Monthly AWS cost budget threshold in USD"
  type        = number
  default     = 10
  validation {
    condition     = var.monthly_budget_usd >= 1 && var.monthly_budget_usd <= 100
    error_message = "monthly_budget_usd must be between $1 and $10 USD to protect Free Tier credits."
  }
}
