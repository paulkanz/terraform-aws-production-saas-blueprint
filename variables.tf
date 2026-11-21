variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-west-2" # Oregon (matches Tualatin local presence)
}

variable "environment" {
  type        = string
  description = "Deployment environment (prod, staging, dev)"
  default     = "prod"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "saas-platform"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.100.0.0/16"
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT gateway to save costs in non-prod"
  default     = false
}

variable "database_instance_class" {
  type        = string
  description = "Aurora MySQL instance class"
  default     = "db.r6g.large"
}

variable "database_instance_count" {
  type        = number
  description = "Number of Aurora instances (1 writer + N readers)"
  default     = 2
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection on Aurora database"
  default     = true
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node type"
  default     = "cache.t4g.medium"
}

variable "container_image" {
  type        = string
  description = "Container image for Production SaaS Platform web and worker service"
  default     = "public.ecr.aws/nginx/nginx:alpine"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the web container"
  default     = 80
}

variable "web_desired_count" {
  type        = number
  description = "Desired number of web tasks"
  default     = 2
}

variable "ssl_certificate_arn" {
  type        = string
  description = "ACM SSL Certificate ARN for HTTPS listener"
  default     = ""
}

variable "enable_efs" {
  type        = bool
  description = "Provision AWS EFS for shared container storage"
  default     = true
}

variable "enable_datadog" {
  type        = bool
  description = "Enable Datadog agent sidecar for APM, metrics, and tracing"
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

variable "github_repository" {
  type        = string
  description = "GitHub repository for OIDC keyless CI/CD deployments (e.g. org/repo)"
  default     = "org/*"
}

variable "enable_migration_tooling" {
  type        = bool
  description = "Provision replication lag alarms and DataSync roles for DigitalOcean to AWS migration"
  default     = true
}


