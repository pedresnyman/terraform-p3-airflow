## cloudwatch groups for airflow
resource "aws_cloudwatch_log_group" "airflow_logs" {
  name              = "/${var.cloudwatch_log_prefix}/dag_runs/"
  retention_in_days = 731
}

## cloudwatch groups for all the ecs tasks
resource "aws_cloudwatch_log_group" "airflow_fargate" {
  for_each          = var.airflow_components
  name              = "/${var.cloudwatch_log_prefix}/${each.key}/"
  retention_in_days = var.airflow_cloudwatch_retention
}
