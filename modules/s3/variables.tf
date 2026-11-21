variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "saas-platform"
}

variable "kms_storage_key_arn" {
  type        = string
  description = "KMS Key ARN for S3 encryption"
}

variable "ecs_task_role_name" {
  type        = string
  description = "Name of ECS Task Role to grant document access"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
