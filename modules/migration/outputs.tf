output "replication_lag_alarm_arn" {
  description = "ARN of the Aurora replication lag alarm"
  value       = aws_cloudwatch_metric_alarm.aurora_replication_lag.arn
}

output "datasync_role_arn" {
  description = "ARN of IAM role for DataSync S3 replication"
  value       = aws_iam_role.datasync_s3.arn
}
