output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = module.ecs.ecs_cluster_name
}

output "web_service_name" {
  description = "ECS Web Service Name"
  value       = module.ecs.web_service_name
}

output "worker_service_name" {
  description = "ECS Queue Worker Service Name"
  value       = module.ecs.worker_service_name
}

output "aurora_endpoint" {
  description = "Aurora MySQL Primary Writer Endpoint"
  value       = module.database.cluster_endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora MySQL Reader Replica Endpoint"
  value       = module.database.reader_endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis Primary Endpoint"
  value       = module.redis.primary_endpoint_address
}

output "documents_bucket_name" {
  description = "S3 Bucket for Vendor Insurance & Compliance Documents"
  value       = module.s3.documents_bucket_name
}

output "waf_web_acl_arn" {
  description = "ARN of WAF Web ACL protecting ALB"
  value       = module.security.waf_web_acl_arn
}

output "github_actions_deploy_role_arn" {
  description = "IAM Role ARN for GitHub Actions keyless OIDC deployment"
  value       = module.security.github_actions_role_arn
}

output "vanta_auditor_role_arn" {
  description = "IAM Role ARN for Vanta SOC 2 automated audit scanning"
  value       = module.security.vanta_auditor_role_arn
}

output "efs_file_system_id" {
  description = "EFS File System ID"
  value       = var.enable_efs ? module.efs[0].file_system_id : null
}

output "internal_dns_zone" {
  description = "Route53 Private DNS Zone Name"
  value       = module.route53.zone_name
}

output "aurora_migration_lag_alarm_arn" {
  description = "CloudWatch Alarm ARN monitoring DigitalOcean to Aurora replication lag"
  value       = var.enable_migration_tooling ? module.migration[0].replication_lag_alarm_arn : null
}

