variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "saas-platform"
}

variable "aurora_cluster_id" {
  type        = string
  description = "Aurora Cluster ID to monitor for replication lag"
}

variable "replication_lag_threshold_seconds" {
  type        = number
  description = "Alert threshold for replication lag in seconds"
  default     = 30
}

variable "alarm_sns_topic_arns" {
  type        = list(string)
  description = "List of SNS topic ARNs for migration alerts"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
