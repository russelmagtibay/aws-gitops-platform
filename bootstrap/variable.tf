variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS region for the state bucket and all project resources"
}

variable "project_name" {
  type        = string
  default     = "aws-gitops-platform"
  description = "Prefix used to name every resource in this project"

}

variable "github_owner" {
  description = "GitHub username or organization that owns the repository"
  type        = string
  default     = "russelmagtibay"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the pipeline roles"
  type        = string
  default     = "aws-gitops-platform"
}