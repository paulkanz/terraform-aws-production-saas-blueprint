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

variable "app_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for EFS mount targets (private app subnets)"
}

variable "ecs_web_security_group_id" {
  type        = string
  description = "Security group ID for ECS Web Service"
}

variable "ecs_worker_security_group_id" {
  type        = string
  description = "Security group ID for ECS Worker Service"
}

variable "kms_storage_key_arn" {
  type        = string
  description = "KMS Storage Key ARN for EFS encryption at rest"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
