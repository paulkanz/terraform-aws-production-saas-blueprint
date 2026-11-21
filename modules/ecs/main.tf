# --- Application Load Balancer (NIST SC-7, CIS AWS Benchmark 2.4.1) ---

resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  # HTTP Desync / Smuggling Defense (CIS Benchmark)
  drop_invalid_header_fields = true
  enable_deletion_protection = var.environment == "prod"

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-alb"
    Compliance = "CIS-AWS-2.4.1-NIST-SC-7"
  })
}

# Associate ALB with WAF v2 WebACL
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}

# ALB Target Group
resource "aws_lb_target_group" "web" {
  name                 = "${var.project}-${var.environment}-tg"
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/up" # Laravel 11+ default health check endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tg"
  })
}

# HTTP Listener (Redirect to HTTPS or Forward if SSL not yet configured)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.ssl_certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.ssl_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.ssl_certificate_arn == "" ? aws_lb_target_group.web.arn : null
  }
}

# HTTPS Listener (TLS 1.2+ Enforced, CIS Benchmark 2.4.1)
resource "aws_lb_listener" "https" {
  count             = var.ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# --- CloudWatch Log Groups (KMS Encrypted, NIST AU-9) ---

resource "aws_cloudwatch_log_group" "ecs_web" {
  name              = "/ecs/${var.project}-${var.environment}-web"
  retention_in_days = 90
  kms_key_id        = var.kms_logs_key_arn

  tags = merge(var.tags, {
    Compliance = "NIST-800-53-AU-9"
  })
}

resource "aws_cloudwatch_log_group" "ecs_worker" {
  name              = "/ecs/${var.project}-${var.environment}-worker"
  retention_in_days = 90
  kms_key_id        = var.kms_logs_key_arn

  tags = merge(var.tags, {
    Compliance = "NIST-800-53-AU-9"
  })
}

resource "aws_cloudwatch_log_group" "ecs_scheduler" {
  name              = "/ecs/${var.project}-${var.environment}-scheduler"
  retention_in_days = 90
  kms_key_id        = var.kms_logs_key_arn

  tags = merge(var.tags, {
    Compliance = "NIST-800-53-AU-9"
  })
}

# --- ECS Cluster (Container Insights Enabled, NIST AU-2) ---

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name       = "${var.project}-${var.environment}-cluster"
    Compliance = "NIST-800-53-AU-2"
  })
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# --- ECS Task Definitions ---

# 1. Web Application Task Definition (with optional Datadog APM sidecar & Sentry)
resource "aws_ecs_task_definition" "web" {
  family                   = "${var.project}-${var.environment}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.web_cpu
  memory                   = var.web_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode(concat([
    {
      name      = "app-web"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "APP_ENV", value = var.environment },
        { name = "APP_DEBUG", value = var.environment == "prod" ? "false" : "true" },
        { name = "LOG_CHANNEL", value = "stderr" },
        { name = "DB_CONNECTION", value = "mysql" },
        { name = "SESSION_DRIVER", value = "redis" },
        { name = "QUEUE_CONNECTION", value = "redis" },
        { name = "CACHE_DRIVER", value = "redis" },
        { name = "SENTRY_LARAVEL_DSN", value = var.sentry_dsn },
        { name = "SENTRY_ENVIRONMENT", value = var.environment },
        { name = "SENTRY_TRACES_SAMPLE_RATE", value = "0.2" }
      ]

      secrets = [
        {
          name      = "DB_CREDENTIALS"
          valueFrom = var.db_credentials_secret_arn
        },
        {
          name      = "REDIS_CREDENTIALS"
          valueFrom = var.redis_credentials_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_web.name
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "web"
        }
      }
    }
    ],
    var.enable_datadog ? [
      {
        name      = "datadog-agent"
        image     = "public.ecr.aws/datadog/agent:latest"
        essential = false

        environment = [
          { name = "DD_SITE", value = "datadoghq.com" },
          { name = "ECS_FARGATE", value = "true" },
          { name = "DD_APM_ENABLED", value = "true" },
          { name = "DD_DOGSTATSD_NON_LOCAL_TRAFFIC", value = "true" },
          { name = "DD_LOGS_ENABLED", value = "true" }
        ]

        secrets = var.datadog_api_key_secret_arn != "" ? [
          {
            name      = "DD_API_KEY"
            valueFrom = var.datadog_api_key_secret_arn
          }
        ] : []
      }
  ] : []))

  tags = var.tags
}

# 2. Worker Task Definition (Laravel Queue Workers)
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project}-${var.environment}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode(concat([
    {
      name      = "app-worker"
      image     = var.container_image
      essential = true
      command   = ["php", "artisan", "queue:work", "--tries=3", "--timeout=90"]

      environment = [
        { name = "APP_ENV", value = var.environment },
        { name = "LOG_CHANNEL", value = "stderr" },
        { name = "DB_CONNECTION", value = "mysql" },
        { name = "QUEUE_CONNECTION", value = "redis" },
        { name = "SENTRY_LARAVEL_DSN", value = var.sentry_dsn },
        { name = "SENTRY_ENVIRONMENT", value = var.environment }
      ]

      secrets = [
        {
          name      = "DB_CREDENTIALS"
          valueFrom = var.db_credentials_secret_arn
        },
        {
          name      = "REDIS_CREDENTIALS"
          valueFrom = var.redis_credentials_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_worker.name
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "worker"
        }
      }
    }
    ],
    var.enable_datadog ? [
      {
        name      = "datadog-agent"
        image     = "public.ecr.aws/datadog/agent:latest"
        essential = false

        environment = [
          { name = "DD_SITE", value = "datadoghq.com" },
          { name = "ECS_FARGATE", value = "true" },
          { name = "DD_APM_ENABLED", value = "true" }
        ]

        secrets = var.datadog_api_key_secret_arn != "" ? [
          {
            name      = "DD_API_KEY"
            valueFrom = var.datadog_api_key_secret_arn
          }
        ] : []
      }
  ] : []))

  tags = var.tags
}

# 3. Scheduled Tasks Definition (Laravel Cron - php artisan schedule:run)
resource "aws_ecs_task_definition" "scheduler" {
  family                   = "${var.project}-${var.environment}-scheduler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app-scheduler"
      image     = var.container_image
      essential = true
      command   = ["php", "artisan", "schedule:run"]

      environment = [
        { name = "APP_ENV", value = var.environment },
        { name = "LOG_CHANNEL", value = "stderr" },
        { name = "DB_CONNECTION", value = "mysql" },
        { name = "QUEUE_CONNECTION", value = "redis" }
      ]

      secrets = [
        {
          name      = "DB_CREDENTIALS"
          valueFrom = var.db_credentials_secret_arn
        },
        {
          name      = "REDIS_CREDENTIALS"
          valueFrom = var.redis_credentials_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_scheduler.name
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "scheduler"
        }
      }
    }
  ])

  tags = var.tags
}

# --- EventBridge Scheduler for Laravel Cron (Runs every 1 minute) ---

resource "aws_cloudwatch_event_rule" "laravel_schedule" {
  name                = "${var.project}-${var.environment}-laravel-cron"
  description         = "Triggers Laravel artisan schedule:run every minute"
  schedule_expression = "rate(1 minute)"

  tags = var.tags
}

resource "aws_iam_role" "ecs_events" {
  name = "${var.project}-${var.environment}-ecs-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "ecs_events_run_task" {
  name = "${var.project}-${var.environment}-ecs-events-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = aws_ecs_task_definition.scheduler.arn
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = [var.ecs_execution_role_arn, var.ecs_task_role_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_events_attach" {
  role       = aws_iam_role.ecs_events.name
  policy_arn = aws_iam_policy.ecs_events_run_task.arn
}

resource "aws_cloudwatch_event_target" "ecs_schedule" {
  rule      = aws_cloudwatch_event_rule.laravel_schedule.name
  target_id = "TriggerLaravelScheduler"
  arn       = aws_ecs_cluster.main.arn
  role_arn  = aws_iam_role.ecs_events.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.scheduler.arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets          = var.app_subnet_ids
      security_groups  = [var.ecs_worker_security_group_id]
      assign_public_ip = false
    }
  }
}

# --- ECS Services (Zero-Downtime Rolling Updates) ---

# Web Service
resource "aws_ecs_service" "web" {
  name            = "${var.project}-${var.environment}-web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.web_desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 100 # Guarantee zero downtime during deploy
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [var.ecs_web_security_group_id]
    assign_public_ip = false # Strict private subnet requirement
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "app-web"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}

# Worker Service (Queue Processing)
resource "aws_ecs_service" "worker" {
  name            = "${var.project}-${var.environment}-worker-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [var.ecs_worker_security_group_id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}

# --- Auto-Scaling (Target Tracking CPU 70% & Memory 80%) ---

resource "aws_appautoscaling_target" "web" {
  max_capacity       = var.web_max_capacity
  min_capacity       = var.web_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Target Tracking: CPU 70%
resource "aws_appautoscaling_policy" "web_cpu" {
  name               = "${var.project}-${var.environment}-web-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.web.resource_id
  scalable_dimension = aws_appautoscaling_target.web.scalable_dimension
  service_namespace  = aws_appautoscaling_target.web.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Target Tracking: Memory 80%
resource "aws_appautoscaling_policy" "web_memory" {
  name               = "${var.project}-${var.environment}-web-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.web.resource_id
  scalable_dimension = aws_appautoscaling_target.web.scalable_dimension
  service_namespace  = aws_appautoscaling_target.web.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
