## cloudwatch groups for airflow
resource "aws_cloudwatch_log_group" "airflow_logs" {
  #checkov:skip=CKV_AWS_158
  #checkov:skip=CKV_AWS_338
  #checkov:skip=CKV_AWS_158
  name              = "airflow-logs"
  retention_in_days = 731
}

## cloudwatch groups for all the ecs tasks
resource "aws_cloudwatch_log_group" "airflow_fargate" {
  #checkov:skip=CKV_AWS_158
  #checkov:skip=CKV_AWS_338
  #checkov:skip=CKV_AWS_158
  for_each          = var.airflow_components
  name              = "/airflow-fargate/${each.key}/"
  retention_in_days = var.airflow_cloudwatch_retention
}
