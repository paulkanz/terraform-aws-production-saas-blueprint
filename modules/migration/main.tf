# --- Aurora MySQL Replication Lag CloudWatch Alarm ---
# Alerts the team immediately if the live replica falls behind DigitalOcean Master

resource "aws_cloudwatch_metric_alarm" "aurora_replication_lag" {
  alarm_name          = "${var.project}-${var.environment}-aurora-migration-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraBinlogReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.replication_lag_threshold_seconds
  alarm_description   = "Triggers when Aurora MySQL binlog replication lag behind DigitalOcean exceeds threshold."
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  tags = merge(var.tags, {
    Purpose    = "DigitalOcean-to-AWS-Migration"
    Compliance = "NIST-800-53-CP-9"
  })
}

# --- AWS DataSync IAM Role for Continuous S3 Document Replication ---

resource "aws_iam_role" "datasync_s3" {
  name = "${var.project}-${var.environment}-datasync-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "datasync.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "datasync_s3_policy" {
  name        = "${var.project}-${var.environment}-datasync-s3-policy"
  description = "Permissions for DataSync to write replicated vendor documents to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = "arn:aws:s3:::${var.project}-${var.environment}-vendor-documents"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = "arn:aws:s3:::${var.project}-${var.environment}-vendor-documents/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datasync_attach" {
  role       = aws_iam_role.datasync_s3.name
  policy_arn = aws_iam_policy.datasync_s3_policy.arn
}
