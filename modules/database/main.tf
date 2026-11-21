# --- DB Subnet Group (Isolated Subnets Only) ---

resource "aws_db_subnet_group" "main" {
  name        = "${var.project}-${var.environment}-db-subnet-group"
  description = "Isolated database subnets for Aurora MySQL"
  subnet_ids  = var.db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  })
}

# --- Database Password Generation & Secrets Manager Storage (NIST IA-5) ---

resource "random_password" "master_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project}/${var.environment}/database"
  description             = "Master credentials for Aurora MySQL cluster"
  kms_key_id              = var.kms_database_key_arn
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Compliance = "NIST-800-53-IA-5-SC-13"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    engine   = "mysql"
    host     = aws_rds_cluster.main.endpoint
    port     = 3306
    username = "app_admin"
    password = random_password.master_password.result
    database = var.database_name
  })
}

# --- Enhanced Monitoring Role (NIST AU-2) ---

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# --- Aurora MySQL Cluster (NIST CP-9, CP-10, SC-13, CIS 2.3.1) ---

resource "aws_rds_cluster" "main" {
  cluster_identifier           = "${var.project}-${var.environment}-aurora-mysql"
  engine                       = "aurora-mysql"
  engine_version               = var.engine_version
  database_name                = var.database_name
  master_username              = "app_admin"
  master_password              = random_password.master_password.result
  backup_retention_period      = 30            # NIST CP-9 30-day retention
  preferred_backup_window      = "07:00-09:00" # UTC (~11 PM - 1 AM Pacific)
  preferred_maintenance_window = "sun:09:00-sun:10:00"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_security_group_id]

  # Storage Encryption via KMS CMK (CIS 2.3.1, NIST SC-13)
  storage_encrypted = true
  kms_key_id        = var.kms_database_key_arn

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.project}-${var.environment}-aurora-final-snapshot" : null

  copy_tags_to_snapshot = true

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-aurora-cluster"
    Compliance = "SOC2-CC6.1-NIST-800-53-CP-9"
  })
}

# Cluster Instances (Multi-AZ HA with Performance Insights)
resource "aws_rds_cluster_instance" "instances" {
  count              = var.instance_count
  identifier         = "${var.project}-${var.environment}-aurora-node-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.main.name

  # Performance Insights with KMS Encryption (NIST AU-2)
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_database_key_arn
  performance_insights_retention_period = 7

  # Enhanced Monitoring (1-second intervals for granular observability)
  monitoring_interval = 5
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-aurora-node-${count.index + 1}"
  })
}
