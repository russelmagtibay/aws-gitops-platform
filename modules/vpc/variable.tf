variable "project_name" {
  description = "Prefix used to name VPC resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must only contain lowercase letters, numbers, and hyphens."
  }
}


variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "public_subnets" {
  description = "Map of AZ to public subnet CIDR block"
  type        = map(string)
  default = {
    "ap-southeast-1a" = "10.0.1.0/24"
    "ap-southeast-1b" = "10.0.2.0/24"
  }
  validation {
    condition     = length(var.public_subnets) >= 2
    error_message = "For High Availability (HA), you must specify at least 2 public subnets in different AZs."
  }

  validation {
    condition     = alltrue([for az, cidr in var.public_subnets : can(cidrhost(cidr, 0))])
    error_message = "All public subnet values must be valid IPv4 CIDR blocks."
  }

}


variable "private_subnets" {
  description = "Map of AZ to private subnet CIDR block"
  type        = map(string)
  default = {
    "ap-southeast-1a" = "10.0.11.0/24"
    "ap-southeast-1b" = "10.0.12.0/24"
  }
  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "For High Availability (HA), you must specify at least 2 private subnets in different AZs."
  }
  validation {
    condition     = alltrue([for az, cidr in var.private_subnets : can(cidrhost(cidr, 0))])
    error_message = "All private subnet values must be valid IPv4 CIDR blocks."
  }


}