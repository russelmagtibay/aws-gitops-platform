output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets (ordered)"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets (ordered)"
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnets_by_az" {
  description = "Map of AZ to public subnet ID"
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "private_subnets_by_az" {
  description = "Map of AZ to private subnet ID"
  value       = { for az, s in aws_subnet.private : az => s.id }
}