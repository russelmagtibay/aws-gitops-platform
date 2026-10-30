output "aws_region" {
  value       = var.aws_region
  description = "Region where the project is deployed"
}

output "state_bucket_name" {
  value       = aws_s3_bucket.tfstate.bucket
  description = "S3 bucket that stores Terraform state"
}

output "plan_role_arn" {
  description = "IAM role assumed by pull request pipelines (terraform plan)"
  value       = aws_iam_role.github["plan"].arn
}

output "apply_role_arn" {
  description = "IAM role assumed after approval (terraform apply)"
  value       = aws_iam_role.github["apply"].arn
}
output "app_deploy_role_arn" {
  description = "IAM role assumed by the application pipeline (ECR + ECS)"
  value       = aws_iam_role.github["app-deploy"].arn
}
