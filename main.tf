# --- 1. KMS Customer Managed Keys (NIST SC-12/13, CIS 2.8) ---
module "kms" {
  source      = "./modules/kms"
  environment = var.environment
  project     = var.project
}

# --- 2. 3-Tier Hardened VPC & Flow Logs (NIST SC-7, CIS 3.9) ---
module "vpc" {
  source             = "./modules/vpc"
  environment        = var.environment
  project            = var.project
  vpc_cidr           = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway
  logs_kms_key_arn   = module.kms.logs_key_arn

  depends_on = [module.kms]
}

# --- 3. Security, WAF v2 & IAM Roles (NIST AC-2/3/6, CIS 1.16) ---
module "security" {
  source              = "./modules/security"
  environment         = var.environment
  project             = var.project
  vpc_id              = module.vpc.vpc_id
  container_port      = var.container_port
  kms_storage_key_arn = module.kms.storage_key_arn
  github_repository   = var.github_repository

  depends_on = [module.vpc]
}

# --- 4. S3 Document Storage & Retention (SOC 2, HITRUST, NIST CP-9) ---
module "s3" {
  source              = "./modules/s3"
  environment         = var.environment
  project             = var.project
  kms_storage_key_arn = module.kms.storage_key_arn
  ecs_task_role_name  = module.security.ecs_task_role_name

  depends_on = [module.kms, module.security]
}

# --- 5. Aurora MySQL Multi-AZ Cluster (NIST CP-9, CIS 2.3.1) ---
module "database" {
  source                     = "./modules/database"
  environment                = var.environment
  project                    = var.project
  db_subnet_ids              = module.vpc.db_subnet_ids
  database_security_group_id = module.security.database_security_group_id
  kms_database_key_arn       = module.kms.database_key_arn
  instance_class             = var.database_instance_class
  instance_count             = var.database_instance_count
  deletion_protection        = var.deletion_protection

  depends_on = [module.vpc, module.security, module.kms]
}

# --- 6. ElastiCache Redis Replication Group (NIST SC-8/13) ---
module "redis" {
  source                  = "./modules/redis"
  environment             = var.environment
  project                 = var.project
  db_subnet_ids           = module.vpc.db_subnet_ids
  redis_security_group_id = module.security.redis_security_group_id
  kms_storage_key_arn     = module.kms.storage_key_arn
  node_type               = var.redis_node_type

  depends_on = [module.vpc, module.security, module.kms]
}

# --- 7. AWS EFS Shared Storage (Legacy File Uploads, NIST SC-13) ---
module "efs" {
  count                        = var.enable_efs ? 1 : 0
  source                       = "./modules/efs"
  environment                  = var.environment
  project                      = var.project
  vpc_id                       = module.vpc.vpc_id
  app_subnet_ids               = module.vpc.app_subnet_ids
  ecs_web_security_group_id    = module.security.ecs_web_security_group_id
  ecs_worker_security_group_id = module.security.ecs_worker_security_group_id
  kms_storage_key_arn          = module.kms.storage_key_arn

  depends_on = [module.vpc, module.security, module.kms]
}

# --- 8. ECS Fargate, ALB & Auto-Scaling (NIST AU-2, SC-5) ---
module "ecs" {
  source                       = "./modules/ecs"
  environment                  = var.environment
  project                      = var.project
  vpc_id                       = module.vpc.vpc_id
  public_subnet_ids            = module.vpc.public_subnet_ids
  app_subnet_ids               = module.vpc.app_subnet_ids
  alb_security_group_id        = module.security.alb_security_group_id
  ecs_web_security_group_id    = module.security.ecs_web_security_group_id
  ecs_worker_security_group_id = module.security.ecs_worker_security_group_id
  waf_web_acl_arn              = module.security.waf_web_acl_arn
  kms_logs_key_arn             = module.kms.logs_key_arn
  ecs_execution_role_arn       = module.security.ecs_execution_role_arn
  ecs_task_role_arn            = module.security.ecs_task_role_arn
  db_credentials_secret_arn    = module.database.db_credentials_secret_arn
  redis_credentials_secret_arn = module.redis.redis_credentials_secret_arn
  container_image              = var.container_image
  container_port               = var.container_port
  web_desired_count            = var.web_desired_count
  ssl_certificate_arn          = var.ssl_certificate_arn
  enable_datadog               = var.enable_datadog
  datadog_api_key_secret_arn   = var.datadog_api_key_secret_arn
  sentry_dsn                   = var.sentry_dsn

  depends_on = [module.vpc, module.security, module.database, module.redis]
}

# --- 9. Route53 Private Hosted Zone (Internal Microservices DNS) ---
module "route53" {
  source                 = "./modules/route53"
  environment            = var.environment
  project                = var.project
  vpc_id                 = module.vpc.vpc_id
  aurora_endpoint        = module.database.cluster_endpoint
  aurora_reader_endpoint = module.database.reader_endpoint
  redis_endpoint         = module.redis.primary_endpoint_address
  alb_dns_name           = module.ecs.alb_dns_name

  depends_on = [module.vpc, module.database, module.redis, module.ecs]
}

# --- 10. Migration Tooling & Continuous Replication Alarms ---
module "migration" {
  count             = var.enable_migration_tooling ? 1 : 0
  source            = "./modules/migration"
  environment       = var.environment
  project           = var.project
  aurora_cluster_id = module.database.cluster_id

  depends_on = [module.database]
}
