output "cluster_endpoint" {
  description = "Primary writer endpoint for Aurora MySQL"
  value       = aws_rds_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "Read-only replica endpoint for Aurora MySQL"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_id" {
  description = "Aurora Cluster ID"
  value       = aws_rds_cluster.main.id
}

output "db_credentials_secret_arn" {
  description = "ARN of Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
