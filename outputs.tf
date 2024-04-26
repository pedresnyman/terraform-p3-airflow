output "airflow_fargate_lb_dns" {
  description = "The DNS name of the Airflow Fargate ALB"
  value       = { for key, lb in aws_lb.airflow_fargate : key => lb.dns_name }
}

output "airflow_fargate_ecr_repository" {
  description = "The ECR repository ARN for Airflow"
  value       = aws_ecr_repository.airflow.arn
}

output "airflow_security_groups" {
  description = "IDs of the security groups used by Airflow components"
  value       = { for key, sg in aws_security_group.airflow_fargate_service : key => sg.id }
}

output "airflow_metadata_db_endpoint" {
  description = "The connection endpoint for the Airflow metadata database"
  value       = aws_db_instance.airflow_metadata_db.endpoint
}

output "airflow_task_definition_arns" {
  description = "ARNs of the ECS task definitions for Airflow components"
  value       = { for key, task in aws_ecs_task_definition.airflow_fargate : key => task.arn }
}

output "airflow_autoscaling_policies" {
  description = "Names and ARNs of autoscaling policies applied to Airflow services"
  value       = { for key, policy in aws_appautoscaling_policy.airflow_fargate_policy : key => { "name" = policy.name, "arn" = policy.arn } }
}
