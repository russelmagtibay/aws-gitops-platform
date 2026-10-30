variable "project_name" {
  description = "Prefix used to name the ECR repository"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens."
  }
}

variable "max_image_count" {
  description = "Maximum number of Docker images to retain in ECR before expiring old ones"
  type        = number
  default     = 10

  validation {
    condition     = var.max_image_count >= 2 && var.max_image_count <= 50
    error_message = "max_image_count must be between 2 (for rollback safety) and 50 (to stay within Free Tier storage)."
  }
}