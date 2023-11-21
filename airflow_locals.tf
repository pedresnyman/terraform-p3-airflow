locals {
  # network
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  # aws role
  ecs_role_name   = var.airflow_ecs_role != null ? var.airflow_ecs_role : aws_iam_role.role_ecs_task_execution[0].name
  # ecs tasks/services
  airflow_components = {
    webserver = {
      command       = ["airflow", "webserver"]
      healthcheck   = ["CMD", "curl", "--fail", "http://localhost:8080/health"]
      desired_count = var.webserver_count
    }
    scheduler = {
      command       = ["airflow", "scheduler"]
      healthcheck   = ["CMD-SHELL", "airflow jobs check --job-type SchedulerJob --hostname \"$${HOSTNAME}\""]
      desired_count = var.scheduler_count
    }
    triggerer = {
      command       = ["airflow", "triggerer"]
      healthcheck   = ["CMD-SHELL", "airflow jobs check --job-type TriggererJob --hostname \"$${HOSTNAME}\""]
      desired_count = var.triggerer_count
    }
    # "worker"
    task-executor = {
    }
  }
  # rds database password
  db_password = var.airflow_username_password != null ? var.airflow_username_password : random_password.password[0].result
  #   container definitions
  container_definitions = { for key, value in local.airflow_components :
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
          value = "/airflow-fargate/${key}/"
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
          awslogs-stream-prefix = "airflow-fargate"
        }
      }
    }
  }

  # airflow environmental variables
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
      value = join(",", local.subnet_ids)
    },
    {
      name  = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"
      value = "postgresql+psycopg2://${var.airflow_username}:${local.db_password}@${aws_db_instance.airflow_metadata_db.endpoint}/${var.rds_database_name}"
    },
    {
      name  = "AIRFLOW__WEBSERVER__WARN_DEPLOYMENT_EXPOSURE"
      value = "False"
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
      value = "airflow"
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__CONTAINER_NAME"
      value = "task-executor"
    },
    {
      name  = "AIRFLOW__ECS_FARGATE__TASK_DEFINITION"
      value = "airflow-task-executor"
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
