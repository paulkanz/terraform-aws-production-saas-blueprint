output "zone_id" {
  description = "Route53 Private Zone ID"
  value       = aws_route53_zone.internal.zone_id
}

output "zone_name" {
  description = "Route53 Private Zone Name"
  value       = aws_route53_zone.internal.name
}

output "db_internal_fqdn" {
  description = "Internal FQDN for primary DB"
  value       = aws_route53_record.db.fqdn
}

output "redis_internal_fqdn" {
  description = "Internal FQDN for Redis"
  value       = aws_route53_record.redis.fqdn
}
