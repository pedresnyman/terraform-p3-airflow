output "airflow_fargate_lb_dns" {
  description = "The DNS name of the Airflow Fargate ALB"
  value       = { for key, lb in aws_lb.airflow_fargate : key => lb.dns_name }
}

output "airflow_fargate_ecr_repository" {
  description = "The ECR repository ARN for Airflow"
  value       = aws_ecr_repository.airflow.arn
}