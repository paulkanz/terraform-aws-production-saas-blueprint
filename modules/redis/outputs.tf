output "primary_endpoint_address" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.main.port
}

output "redis_credentials_secret_arn" {
  description = "ARN of Secrets Manager secret containing Redis credentials"
  value       = aws_secretsmanager_secret.redis_credentials.arn
}
