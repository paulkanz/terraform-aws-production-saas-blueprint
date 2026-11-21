output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "ecs_web_security_group_id" {
  description = "Security group ID for ECS Web Service"
  value       = aws_security_group.ecs_web.id
}

output "ecs_worker_security_group_id" {
  description = "Security group ID for ECS Worker Service"
  value       = aws_security_group.ecs_worker.id
}

output "database_security_group_id" {
  description = "Security group ID for Aurora Database"
  value       = aws_security_group.database.id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

output "ecs_execution_role_arn" {
  description = "ARN of ECS Task Execution Role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS Task Role"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_task_role_name" {
  description = "Name of ECS Task Role"
  value       = aws_iam_role.ecs_task.name
}

output "github_actions_role_arn" {
  description = "ARN of GitHub Actions OIDC deployment IAM role"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "vanta_auditor_role_arn" {
  description = "ARN of Vanta SOC 2 automated auditor IAM role"
  value       = aws_iam_role.vanta_auditor.arn
}
