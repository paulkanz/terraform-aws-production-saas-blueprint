variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "saas-platform"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "Private application subnet IDs for ECS tasks"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID for ALB"
}

variable "ecs_web_security_group_id" {
  type        = string
  description = "Security group ID for ECS Web Service"
}

variable "ecs_worker_security_group_id" {
  type        = string
  description = "Security group ID for ECS Worker Service"
}

variable "waf_web_acl_arn" {
  type        = string
  description = "ARN of WAF Web ACL to associate with ALB"
}

variable "kms_logs_key_arn" {
  type        = string
  description = "KMS Key ARN for CloudWatch Log Groups"
}

variable "ecs_execution_role_arn" {
  type        = string
  description = "ARN of ECS Task Execution Role"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "ARN of ECS Task Role"
}

variable "db_credentials_secret_arn" {
  type        = string
  description = "ARN of Secrets Manager secret for DB credentials"
}

variable "redis_credentials_secret_arn" {
  type        = string
  description = "ARN of Secrets Manager secret for Redis credentials"
}

variable "container_image" {
  type        = string
  description = "Docker image URI for Production SaaS Platform web app"
  default     = "public.ecr.aws/nginx/nginx:alpine" # Default placeholder until ECR repo populated
}

variable "container_port" {
  type        = number
  description = "Port exposed by the web container"
  default     = 80
}

variable "web_cpu" {
  type        = number
  description = "CPU units for web task (1024 = 1 vCPU)"
  default     = 1024
}

variable "web_memory" {
  type        = number
  description = "Memory (MB) for web task"
  default     = 2048
}

variable "web_desired_count" {
  type        = number
  description = "Desired number of web tasks"
  default     = 2
}

variable "web_min_capacity" {
  type        = number
  description = "Minimum number of auto-scaled web tasks"
  default     = 2
}

variable "web_max_capacity" {
  type        = number
  description = "Maximum number of auto-scaled web tasks"
  default     = 10
}

variable "worker_cpu" {
  type        = number
  description = "CPU units for worker task"
  default     = 1024
}

variable "worker_memory" {
  type        = number
  description = "Memory (MB) for worker task"
  default     = 2048
}

variable "worker_desired_count" {
  type        = number
  description = "Desired number of queue worker tasks"
  default     = 2
}

variable "ssl_certificate_arn" {
  type        = string
  description = "ACM SSL Certificate ARN for HTTPS listener (optional, falls back to HTTP-only if blank)"
  default     = ""
}

variable "enable_datadog" {
  type        = bool
  description = "Enable Datadog agent sidecar for APM, tracing, and metric collection"
  default     = true
}

variable "datadog_api_key_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for Datadog API Key"
  default     = ""
}

variable "sentry_dsn" {
  type        = string
  description = "Sentry DSN for application error tracking"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
