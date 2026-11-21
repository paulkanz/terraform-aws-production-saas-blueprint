output "file_system_id" {
  description = "EFS File System ID"
  value       = aws_efs_file_system.main.id
}

output "file_system_arn" {
  description = "EFS File System ARN"
  value       = aws_efs_file_system.main.arn
}

output "access_point_id" {
  description = "EFS Access Point ID"
  value       = aws_efs_access_point.app_storage.id
}

output "efs_security_group_id" {
  description = "Security group ID for EFS"
  value       = aws_security_group.efs.id
}
