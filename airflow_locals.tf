locals {
  # container definitions
  container_definitions = { for key, value in var.airflow_components :
    key => {
      name  = key
      image = join(":", [aws_ecr_repository.airflow.repository_url, "latest"])
      # Only map port 8080 when it's the webserver
      portMappings = key == "webserver" ? [{
        containerPort = 8080
      }] : null
      healthcheck = contains(keys(value), "healthcheck") ? {
        command  = value.healthcheck
        interval = 35
        timeout  = 30
        retries  = 5
      } : null
      essential = true
      command   = lookup(value, "command", [])
      linuxParameters = {
        initProcessEnabled = var.enable_execute_command
      }
      environment = concat(local.airflow_environment_variables, [
        {
          name  = "LOG_GROUP",
          value = "/${var.cloudwatch_log_prefix}/${key}/"
        },
        {
          name  = "AIRFLOW__ECS_FARGATE__SECURITY_GROUPS"
          value = aws_security_group.airflow_fargate_service[key].id
        }
      ])
      user = "50000:0"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_fargate[key].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.cloudwatch_log_prefix
        }
      }
    }
  }

  airflow_environment_static_variables = [
    {
      name  = "AIRFLOW__ECS_FARGATE__REGION"
      value = var.aws_region
    },
    {
      name  = "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER"
      value = "cloudwatch://${aws_cloudwatch_log_group.airflow_logs.arn}:*"
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__SUBNETS"
      value = join(",", var.subnets)
    },
    {
      name  = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"
      value = "postgresql+psycopg2://${jsondecode(data.aws_secretsmanager_secret_version.airflow_metadata_db_secret_version.secret_string)["username"]}:${jsondecode(data.aws_secretsmanager_secret_version.airflow_metadata_db_secret_version.secret_string)["password"]}@${aws_db_instance.airflow_metadata_db.endpoint}/airflow"
    },
    {
      name  = "AIRFLOW__CORE__EXECUTOR"
      value = "aws_executors_plugin.AwsEcsFargateExecutor"
    },
    {
      name  = "AIRFLOW__CORE__PARALLELISM"
      value = "100"
    },
    {
      name  = "AIRFLOW__CORE__MAX_ACTIVE_TASKS_PER_DAG"
      value = "100"
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__CLUSTER"
      value = var.ecs_cluster_name
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__CONTAINER_NAME"
      value = "task-executor"
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__TASK_DEFINITION"
      value = aws_ecs_task_definition.airflow_fargate["task-executor"].id
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__LAUNCH_TYPE"
      value = "FARGATE"
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__PLATFORM_VERSION"
      value = "LATEST"
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__ASSIGN_PUBLIC_IP"
      value = "DISABLED"
    },
    {
      name  = "AIRFLOW__LOGGING__REMOTE_LOGGING"
      value = "True"
    },
    {
      name  = "AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID"
      value = "aws_default"
    },
  ]
  # Combine static and dynamic variables
  airflow_environment_variables = concat(local.airflow_environment_static_variables, var.airflow_environment_variables)
}
