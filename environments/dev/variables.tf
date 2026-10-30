variable "aws_region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "ap-southeast-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format (e.g., ap-southeast-1)."
  }
}

variable "project_name" {
  description = "Prefix used to name all platform resources"
  type        = string
  default     = "aws-gitops-platform"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name)) && length(var.project_name) <= 24
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens (max 24 chars)."
  }
}

variable "alert_email" {
  description = "Email address for CloudWatch and AWS Budget notifications"
  type        = string
  default     = "russelmagtibay15@gmail.com"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}