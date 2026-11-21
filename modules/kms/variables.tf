variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. prod, staging)"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "saas-platform"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
