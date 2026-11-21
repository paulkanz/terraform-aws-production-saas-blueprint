variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "saas-platform"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "Isolated database subnet IDs"
}

variable "redis_security_group_id" {
  type        = string
  description = "Security group ID for Redis"
}

variable "node_type" {
  type        = string
  description = "ElastiCache node instance type"
  default     = "cache.t4g.medium"
}

variable "num_cache_clusters" {
  type        = number
  description = "Number of cache nodes (1 primary + N replicas)"
  default     = 2
}

variable "kms_storage_key_arn" {
  type        = string
  description = "KMS Storage Key ARN for secret storage"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
