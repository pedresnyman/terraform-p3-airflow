# ecs task definiion
resource "aws_ecs_task_definition" "airflow_fargate" {
  for_each           = local.airflow_components
  family             = "airflow-${each.key}"
  cpu                = each.value.cpu
  memory             = each.value.memory
  execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.this_account.account_id}:role/${local.ecs_role_name}"
  task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.this_account.account_id}:role/${local.ecs_role_name}"
  network_mode       = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  requires_compatibilities = ["FARGATE"]
  container_definitions    = jsonencode([local.container_definitions[each.key]])
}

