variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "saas-platform"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private application subnets"
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for isolated database subnets"
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "single_nat_gateway" {
  type        = bool
  description = "Set true for single NAT gateway (cost saving in dev/staging), false for multi-AZ NAT (prod HA)"
  default     = false
}

variable "logs_kms_key_arn" {
  type        = string
  description = "KMS Key ARN for VPC Flow Logs"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
