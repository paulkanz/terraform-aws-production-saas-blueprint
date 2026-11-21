# --- Security Group for EFS (NFS Port 2049, Least Privilege) ---

resource "aws_security_group" "efs" {
  name        = "${var.project}-${var.environment}-efs-sg"
  description = "Security group for EFS Mount Targets"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from ECS Web Tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.ecs_web_security_group_id]
  }

  ingress {
    description     = "NFS from ECS Worker Tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.ecs_worker_security_group_id]
  }

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-efs-sg"
    Compliance = "NIST-800-53-AC-4"
  })
}

# --- AWS EFS File System (KMS Encrypted At-Rest, NIST SC-13, CIS Benchmark) ---

resource "aws_efs_file_system" "main" {
  creation_token = "${var.project}-${var.environment}-efs"
  encrypted      = true
  kms_key_id     = var.kms_storage_key_arn

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-efs"
    Compliance = "NIST-800-53-SC-13-SOC2-CC6.1"
  })
}

# EFS Mount Targets in each Private Application Subnet
resource "aws_efs_mount_target" "mount_targets" {
  count           = length(var.app_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.app_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# EFS Access Point with POSIX Identity (www-data: uid 1000, gid 1000)
resource "aws_efs_access_point" "app_storage" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/storage"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-efs-ap"
  })
}
