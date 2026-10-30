# 1. Build the Multi-AZ VPC, Subnets, Internet Gateway & NAT Gateway
module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
}

# 2. Build the ALB & ECS Firewalls inside the VPC
module "security" {
  source       = "../../modules/security"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# 3. Build the Public Load Balancer inside the Public Subnets
module "alb" {
  source            = "../../modules/alb"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

# 4. Build the Private Docker Image Registry
module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
}

# 5. Build the ECS Fargate Cluster & 2 Containers inside the Private Subnets
module "ecs" {
  source             = "../../modules/ecs"
  project_name       = var.project_name
  aws_region         = var.aws_region
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_tasks_sg_id    = module.security.ecs_tasks_sg_id
  target_group_arn   = module.alb.target_group_arn
}

# 6. Build the CloudWatch Alarms, SNS Email Alerts & $10 Monthly Budget
module "monitoring" {
  source         = "../../modules/monitoring"
  project_name   = var.project_name
  cluster_name   = module.ecs.cluster_name
  service_name   = module.ecs.service_name
  alb_arn_suffix = module.alb.alb_arn_suffix
  alert_email    = var.alert_email
}