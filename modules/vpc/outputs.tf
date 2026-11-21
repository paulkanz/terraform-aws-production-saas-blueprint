output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "List of private application subnet IDs"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "List of isolated database subnet IDs"
  value       = aws_subnet.db[*].id
}

output "app_subnet_cidrs" {
  description = "List of app subnet CIDR blocks"
  value       = var.app_subnet_cidrs
}

output "vpce_security_group_id" {
  description = "Security group ID for VPC Interface Endpoints"
  value       = aws_security_group.endpoints.id
}
