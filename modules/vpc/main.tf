resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-vpc"
    Compliance = "NIST-800-53-SC-7"
  })
}

# Default Security Group Hardening (CIS AWS Benchmark 4.3 - no inbound/outbound rules)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-default-sg-hardened"
    Compliance = "CIS-AWS-4.3"
  })
}

# --- Subnets ---

# Public Subnets (ALB & NAT)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # CIS requirement: no auto-assign public IPs

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-public-${var.availability_zones[count.index]}"
    Tier = "Public"
  })
}

# Private Application Subnets (ECS Fargate Tasks)
resource "aws_subnet" "app" {
  count             = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-app-${var.availability_zones[count.index]}"
    Tier = "Application"
  })
}

# Isolated Database Subnets (Aurora MySQL & Redis - No Internet Gateway Route)
resource "aws_subnet" "db" {
  count             = length(var.db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-db-${var.availability_zones[count.index]}"
    Tier = "Database"
  })
}

# --- Gateways & Routing ---

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-igw"
  })
}

# NAT Gateways
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-public-rt"
  })
}

resource "aws_route_table" "app" {
  count  = length(var.app_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-app-rt-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  # Completely isolated - no default internet route (NIST SC-7)
  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-db-rt-isolated"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  count          = length(var.app_subnet_cidrs)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

resource "aws_route_table_association" "db" {
  count          = length(var.db_subnet_cidrs)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

# --- VPC Flow Logs (CIS Benchmark 3.9, NIST AU-2 / AU-12) ---

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project}-${var.environment}-flow-logs"
  retention_in_days = 90
  kms_key_id        = var.logs_kms_key_arn

  tags = merge(var.tags, {
    Compliance = "CIS-AWS-3.9"
  })
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.project}-${var.environment}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project}-${var.environment}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-flow-log"
    Compliance = "CIS-AWS-3.9"
  })
}

# --- VPC Endpoints (PrivateLink: Secure AWS API Access without Internet Traversal) ---

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.availability_zones[0] != "" ? substr(var.availability_zones[0], 0, length(var.availability_zones[0]) - 1) : "us-west-2"}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id, aws_route_table.db.id], aws_route_table.app[*].id)

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-s3-endpoint"
  })
}

# Security group for Interface Endpoints
resource "aws_security_group" "endpoints" {
  name        = "${var.project}-${var.environment}-vpce-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from Application Subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.app_subnet_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-vpce-sg"
  })
}
