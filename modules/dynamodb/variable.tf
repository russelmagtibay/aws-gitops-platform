variable "project_name" {
  description = "Prefix used to name the DynamoDB leads table"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens."
  }
}