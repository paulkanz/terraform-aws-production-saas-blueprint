# --- Route53 Private Hosted Zone (Internal DNS, NIST SC-7) ---

resource "aws_route53_zone" "internal" {
  name    = "${var.environment}.${var.domain_name}"
  comment = "Private DNS for Production SaaS Platform ${var.environment} microservices and databases"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-internal-dns"
  })
}

# 1. Primary Database CNAME (Writer)
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "db.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = 30
  records = [var.aurora_endpoint]
}

# 2. Read-Only Database CNAME (Replica)
resource "aws_route53_record" "db_ro" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "db-ro.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = 30
  records = [var.aurora_reader_endpoint]
}

# 3. Redis Cache CNAME
resource "aws_route53_record" "redis" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "redis.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = 30
  records = [var.redis_endpoint]
}

# 4. Internal Application / ALB CNAME
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "app.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = 60
  records = [var.alb_dns_name]
}
