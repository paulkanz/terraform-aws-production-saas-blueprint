output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS Cluster"
  value       = aws_ecs_cluster.main.arn
}

output "web_service_name" {
  description = "Name of the ECS Web Service"
  value       = aws_ecs_service.web.name
}

output "worker_service_name" {
  description = "Name of the ECS Worker Service"
  value       = aws_ecs_service.worker.name
}
