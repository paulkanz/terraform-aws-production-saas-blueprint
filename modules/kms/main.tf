data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS Key for S3 & Application Storage (NIST SC-13, CIS 2.8)
resource "aws_kms_key" "storage" {
  description             = "${var.project}-${var.environment}-storage-cmk"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-storage-kms"
    Compliance = "NIST-800-53-SC-12-SC-13"
    CIS        = "2.8"
  })
}

resource "aws_kms_alias" "storage" {
  name          = "alias/${var.project}-${var.environment}-storage"
  target_key_id = aws_kms_key.storage.key_id
}

# KMS Key for Aurora Database (NIST SC-13, CIS 2.8, SOC 2 CC6.1)
resource "aws_kms_key" "database" {
  description             = "${var.project}-${var.environment}-database-cmk"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-database-kms"
    Compliance = "NIST-800-53-SC-12-SC-13"
    CIS        = "2.8"
  })
}

resource "aws_kms_alias" "database" {
  name          = "alias/${var.project}-${var.environment}-database"
  target_key_id = aws_kms_key.database.key_id
}

# KMS Key for CloudWatch Logs (NIST AU-9, CIS 2.8)
data "aws_iam_policy_document" "cloudwatch_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudWatch Logs Service"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }
}

resource "aws_kms_key" "logs" {
  description             = "${var.project}-${var.environment}-cloudwatch-logs-cmk"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudwatch_kms.json

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-logs-kms"
    Compliance = "NIST-800-53-AU-9"
    CIS        = "2.8"
  })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project}-${var.environment}-logs"
  target_key_id = aws_kms_key.logs.key_id
}
