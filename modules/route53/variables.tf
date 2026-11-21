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
  description = "VPC ID to associate private hosted zone"
}

variable "aurora_endpoint" {
  type        = string
  description = "Aurora MySQL primary writer endpoint"
}

variable "aurora_reader_endpoint" {
  type        = string
  description = "Aurora MySQL reader endpoint"
}

variable "redis_endpoint" {
  type        = string
  description = "ElastiCache Redis primary endpoint"
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name"
}

variable "domain_name" {
  type        = string
  description = "Internal domain name"
  default     = "app.internal"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
