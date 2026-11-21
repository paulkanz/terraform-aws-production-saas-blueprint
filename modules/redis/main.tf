# Subnet Group for Redis
resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.project}-${var.environment}-redis-subnet-group"
  description = "Isolated database subnets for Redis"
  subnet_ids  = var.db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-redis-subnet-group"
  })
}

# Redis Auth Token Generation & Secret Storage (NIST IA-5)
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false # Redis auth token must not contain special characters
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  name                    = "${var.project}/${var.environment}/redis"
  description             = "Auth token for Redis Cluster"
  kms_key_id              = var.kms_storage_key_arn
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_credentials" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id
  secret_string = jsonencode({
    host       = aws_elasticache_replication_group.main.primary_endpoint_address
    port       = 6379
    auth_token = random_password.redis_auth_token.result
  })
}

# Redis Replication Group (Multi-AZ, In-Transit & At-Rest Encryption)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project}-${var.environment}-redis"
  description          = "Redis cluster for Laravel sessions, cache, and queues"
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  port                 = 6379
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.redis_security_group_id]

  # High Availability & Failover
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # Encryption & Security (NIST SC-8, SC-13, SOC 2 CC6.1)
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result

  auto_minor_version_upgrade = true
  maintenance_window         = "sun:06:00-sun:07:00"

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-redis"
    Compliance = "SOC2-CC6.1-NIST-800-53-SC-8"
  })
}
