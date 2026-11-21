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

variable "container_port" {
  type        = number
  description = "Port exposed by the web container"
  default     = 80
}

variable "kms_storage_key_arn" {
  type        = string
  description = "ARN of KMS Storage Key for IAM decryption"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository path for OIDC federation (e.g. org/repo or org/*)"
  default     = "org/*"
}

variable "vanta_external_id" {
  type        = string
  description = "External ID for Vanta SOC 2 auditor IAM role"
  default     = "vanta-audit-integration"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
