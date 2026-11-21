output "documents_bucket_name" {
  description = "Name of vendor documents S3 bucket"
  value       = aws_s3_bucket.documents.id
}

output "documents_bucket_arn" {
  description = "ARN of vendor documents S3 bucket"
  value       = aws_s3_bucket.documents.arn
}

output "access_logs_bucket_name" {
  description = "Name of access logs S3 bucket"
  value       = aws_s3_bucket.access_logs.id
}
