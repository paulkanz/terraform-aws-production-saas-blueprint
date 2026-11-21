# --- AWS WAF v2 WebACL (NIST SC-7, CIS AWS Benchmark, OWASP Top 10) ---

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project}-${var.environment}-web-acl"
  description = "WAF protection for Production SaaS Platform ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: AWS Managed Common Rule Set (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Known Bad Inputs Rule Set
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Amazon IP Reputation List
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IpReputationMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: Rate Limiting (DDoS & Brute Force Mitigation - 2000 requests per 5 mins per IP)
  rule {
    name     = "RateLimitRule"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-waf-metrics"
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, {
    Compliance = "NIST-800-53-SC-7"
  })
}

# --- Security Groups (Principle of Least Privilege / Zero Trust) ---

# 1. Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for public ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP for redirect to HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alb-sg"
  })
}

# 2. ECS Fargate Web Application Security Group
resource "aws_security_group" "ecs_web" {
  name        = "${var.project}-${var.environment}-ecs-web-sg"
  description = "Security group for ECS Web Service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic strictly from ALB SG"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound (NAT/Endpoints for DB, Redis, APIs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ecs-web-sg"
  })
}

# ALB Egress strictly to ECS Web SG
resource "aws_security_group_rule" "alb_egress_to_ecs" {
  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_web.id
  security_group_id        = aws_security_group.alb.id
}

# 3. ECS Fargate Worker Security Group (Queue Workers / Cron Tasks)
resource "aws_security_group" "ecs_worker" {
  name        = "${var.project}-${var.environment}-ecs-worker-sg"
  description = "Security group for ECS Worker Tasks"
  vpc_id      = var.vpc_id

  # No ingress required for background workers! (Principle of least privilege)

  egress {
    description = "Allow all outbound (NAT/Endpoints for DB, Redis, S3)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ecs-worker-sg"
  })
}

# 4. Aurora MySQL Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "Security group for Aurora MySQL Cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from ECS Web Tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_web.id]
  }

  ingress {
    description     = "MySQL from ECS Worker Tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_worker.id]
  }

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-db-sg"
    Compliance = "NIST-800-53-AC-4"
  })
}

# 5. ElastiCache Redis Security Group
resource "aws_security_group" "redis" {
  name        = "${var.project}-${var.environment}-redis-sg"
  description = "Security group for Redis Cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from ECS Web Tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_web.id]
  }

  ingress {
    description     = "Redis from ECS Worker Tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_worker.id]
  }

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-redis-sg"
    Compliance = "NIST-800-53-AC-4"
  })
}

# --- IAM Roles (Least Privilege, NIST AC-6, CIS 1.16) ---

# ECS Task Execution Role (Pull image, write logs, get KMS decrypted secrets)
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_standard" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow execution role to read Secrets Manager secrets and decrypt with KMS
resource "aws_iam_policy" "ecs_secrets" {
  name        = "${var.project}-${var.environment}-ecs-secrets-policy"
  description = "Allow ECS to fetch Secrets Manager parameters and decrypt via KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project}/${var.environment}/*"
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = var.kms_storage_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_attach" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_secrets.arn
}

# ECS Task Role (Runtime permissions for the container process)
resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# --- AWS Bedrock AI Integration Policy (JD "Nice to Have" - LLM / Claude 3.5 Sonnet) ---

resource "aws_iam_policy" "ecs_bedrock" {
  name        = "${var.project}-${var.environment}-ecs-bedrock-policy"
  description = "Allows ECS tasks to invoke AWS Bedrock LLM models (e.g. Anthropic Claude 3.5)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockInvokeModel"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-*",
          "arn:aws:bedrock:*::foundation-model/amazon.titan-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_bedrock_attach" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_bedrock.arn
}

# --- GitHub Actions OIDC Authentication (Keyless CI/CD, NIST AC-2, CIS 1.16) ---

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f8d44649c1"]

  tags = var.tags
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "${var.project}-${var.environment}-github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_actions.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "github_actions_ecs_deploy" {
  name        = "${var.project}-${var.environment}-github-deploy-policy"
  description = "Permissions for GitHub Actions to deploy ECS services and register tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:ListTaskDefinitions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_ecs_deploy.arn
}

# --- Vanta SOC 2 Automated Compliance Auditor Role (JD Specific) ---

resource "aws_iam_role" "vanta_auditor" {
  name = "${var.project}-${var.environment}-vanta-auditor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::956984688945:root" # Official Vanta AWS Account ID
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "sts:ExternalId" = var.vanta_external_id
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Compliance = "SOC2-Vanta-Automated-Audit"
  })
}

resource "aws_iam_role_policy_attachment" "vanta_security_audit" {
  role       = aws_iam_role.vanta_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

