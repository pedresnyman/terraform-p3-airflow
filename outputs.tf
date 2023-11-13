output "airflow_fargate_lb_dns" {
  description = "The DNS name of the Airflow Fargate ALB"
  value       = { for key, lb in aws_lb.airflow_fargate : key => lb.dns_name }
}

output "airflow_fargate_ecr_repository" {
  description = "The ECR repository ARN for Airflow"
  value       = aws_ecr_repository.airflow.arn
}

output "public_subnet_ids" {
  value = length(module.vpc) > 0 ? module.vpc[0].public_subnets : []
}

output "password" {
  value = length(random_password.password) > 0 ? random_password.password[0].result : "Not generated"
}
