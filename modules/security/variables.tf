variable "project_name" {
  description = "Prefix used to name Security Groups"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens."
  }
}



variable "vpc_id" {
  description = "VPC ID where Security Groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID starting with 'vpc-'."
  }
}


variable "container_port" {
  description = "Unprivileged port exposed by the FastAPI container"
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port >= 1024 && var.container_port <= 65535 && !contains([22, 3389], var.container_port)
    error_message = "container_port must be an unprivileged port between 1024 and 65535 (never SSH 22 or RDP 3389)."
  }
}

variable "alb_ingress_cidrs" {
  description = "Map of rule names to allowed IPv4 CIDR blocks for ALB HTTP ingress"
  type        = map(string)
  default = {
    "public-internet" = "0.0.0.0/0"
  }
  validation {
    condition     = length(var.alb_ingress_cidrs) > 0 && alltrue([for name, cidr in var.alb_ingress_cidrs : can(cidrhost(cidr, 0))])
    error_message = "alb_ingress_cidrs must contain at least one valid IPv4 CIDR block (e.g., 0.0.0.0/0)."
  }
}