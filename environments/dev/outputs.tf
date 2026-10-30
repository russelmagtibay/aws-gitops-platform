output "alb_url" {
  description = "Public HTTP URL of the Application Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR Repository URL for pushing Docker images"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Fargate Cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS Fargate Service name"
  value       = module.ecs.service_name
}