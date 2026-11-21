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

variable "database_security_group_id" {
  type        = string
  description = "Security group ID for Aurora"
}

variable "kms_database_key_arn" {
  type        = string
  description = "KMS Key ARN for Aurora database storage encryption"
}

variable "engine_version" {
  type        = string
  description = "Aurora MySQL engine version"
  default     = "8.0.mysql_aurora.3.05.2"
}

variable "instance_class" {
  type        = string
  description = "DB instance class"
  default     = "db.r6g.large"
}

variable "instance_count" {
  type        = number
  description = "Number of Aurora instances (1 writer + N readers)"
  default     = 2
}

variable "database_name" {
  type        = string
  description = "Initial database name"
  default     = "saas-platform"
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection on production clusters"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
