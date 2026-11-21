output "storage_key_arn" {
  description = "ARN of KMS key for S3 and general storage"
  value       = aws_kms_key.storage.arn
}

output "storage_key_id" {
  description = "ID of KMS key for S3 and general storage"
  value       = aws_kms_key.storage.key_id
}

output "database_key_arn" {
  description = "ARN of KMS key for Aurora Database"
  value       = aws_kms_key.database.arn
}

output "logs_key_arn" {
  description = "ARN of KMS key for CloudWatch Logs"
  value       = aws_kms_key.logs.arn
}
