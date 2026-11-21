# --- Dedicated Access Logs Bucket (CIS Benchmark 2.1.3, NIST AU-2) ---

resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.project}-${var.environment}-s3-access-logs"
  force_destroy = false

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-s3-access-logs"
    Compliance = "CIS-AWS-2.1.3"
  })
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_storage_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "access_logs_tls" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnforceTLSRequestsOnly"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.access_logs.arn,
        "${aws_s3_bucket.access_logs.arn}/*"
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

# --- Primary Documents Bucket (Vendor Insurance COIs, Contracts, PDFs) ---

resource "aws_s3_bucket" "documents" {
  bucket        = "${var.project}-${var.environment}-vendor-documents"
  force_destroy = false

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-vendor-documents"
    Compliance = "SOC2-CC6.1-HITRUST-NIST-800-53"
  })
}

# 1. Versioning Enabled (NIST CP-9)
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Server-Side Encryption via KMS CMK (NIST SC-13, CIS 2.1.1)
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_storage_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# 3. Block All Public Access (CIS 2.1.2)
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Access Logging Enabled (CIS 2.1.3, NIST AU-2)
resource "aws_s3_bucket_logging" "documents" {
  bucket = aws_s3_bucket.documents.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "vendor-documents-access-logs/"
}

# 5. Enforce TLS 1.2+ Only (NIST SC-8)
resource "aws_s3_bucket_policy" "documents" {
  bucket = aws_s3_bucket.documents.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.documents.arn,
          "${aws_s3_bucket.documents.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# 6. Lifecycle Rules for Compliance Archival (NIST SI-12)
resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# --- Grant ECS Task Role Access to Documents ---

resource "aws_iam_role_policy" "ecs_s3_access" {
  name = "${var.project}-${var.environment}-ecs-s3-access"
  role = var.ecs_task_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.documents.arn,
          "${aws_s3_bucket.documents.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_storage_key_arn
      }
    ]
  })
}
