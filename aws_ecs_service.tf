This is my full code:

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


module "acm" {
  count      = length(var.route53_domain_name) > 0 ? 1 : 0
  source     = "terraform-aws-modules/acm/aws"
  version    = "3.5.0"

  domain_name = var.route53_domain_name
  zone_id     = aws_route53_zone.airflow_zone[0].zone_id

  subject_alternative_names = [
    "*.${var.route53_domain_name}",
  ]

  wait_for_validation = true

  tags = {
    Name = var.route53_domain_name
  }
}

## autoscaling
resource "aws_appautoscaling_target" "airflow_fargate_target" {
  for_each           = { for key, value in var.airflow_components : key => value if lookup(value, "desired_count", null) != null }
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.airflow.name}/${aws_ecs_service.airflow_fargate[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "airflow_fargate_policy" {
  for_each           = { for key, value in var.airflow_components : key => value if lookup(value, "desired_count", null) != null }
  name               = "cpu-utilization-${each.key}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.airflow_fargate_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.airflow_fargate_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.airflow_fargate_target[each.key].service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = var.autoscale_cpu_avg_usage
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

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

# ecr repository for the airflow environment
resource "aws_ecr_repository" "airflow" {
  name = var.ecr_repository_name
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECS cluster for our Airflow deployment
resource "aws_ecs_cluster" "airflow" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Allow services in our cluster to use fargate or fargate_spot.
# Place all tasks in fargate_spot by default.
resource "aws_ecs_cluster_capacity_providers" "airflow" {
  cluster_name       = aws_ecs_cluster.airflow.name
  capacity_providers = var.capacity_providers
  default_capacity_provider_strategy {
    weight            = 1
    base              = 1
    capacity_provider = var.use_spot ? "FARGATE_SPOT" : "FARGATE"
  }
}

# ecs task definiion
resource "aws_ecs_task_definition" "airflow_fargate" {
  for_each           = var.airflow_components
  family             = "airflow-${each.key}"
  cpu                = var.cpu
  memory             = var.memory
  execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.this_account.account_id}:role/${var.airflow_ecs_role}"
  task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.this_account.account_id}:role/${var.airflow_ecs_role}"
  network_mode       = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  requires_compatibilities = ["FARGATE"]
  container_definitions    = jsonencode([local.container_definitions[each.key]])
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  count       = var.airflow_ecs_role != "role-ecs-task-execution" ? 1 : 0
  name        = "pol-ecs-task-execution"
  description = "Policy for ECS Task Execution"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:Describe*",
        "logs:Get*",
        "logs:List*",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
          "ecs:ExecuteCommand",
          "ecs:DescribeTasks"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ssm:StartSession",
            "ssm:TerminateSession",
            "ssm:DescribeSessions",
            "ssm:GetConnectionStatus",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "role_ecs_task_execution" {
  count                = var.airflow_ecs_role != "role-ecs-task-execution" ? 1 : 0
  name                 = "role-ecs-task-execution"
  assume_role_policy   = data.aws_iam_policy_document.role_ecs_task_execution_assume_policy.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "role_ecs_task_execution_assume_policy" {
  count = var.airflow_ecs_role != "role-ecs-task-execution" ? 1 : 0
  statement {
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "role_ecs_task_execution_attach" {
  count      = var.airflow_ecs_role != "role-ecs-task-execution" ? 1 : 0
  role       = aws_iam_role.role_ecs_task_execution[0].name
  policy_arn = aws_iam_policy.ecs_task_execution_policy[0].arn
}

# resource block for KMS key
resource "aws_kms_key" "airflow_kms" {
  description             = "KMS key for Airflow metadb"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

locals {
  create_http_listener = length(var.route53_domain_name) > 0 && length(var.route53_dns_name) > 0
  create_https_listener = length(var.route53_domain_name) > 0 && length(var.route53_dns_name) > 0
  create_plain_http_listener = length(var.route53_domain_name) == 0 || length(var.route53_dns_name) == 0
}



# application load balancer
# this allows us to have high availability
resource "aws_lb" "airflow_fargate" {
  for_each           = { for key, value in var.airflow_components : key => value if key == "webserver" }
  name               = "airflow-${each.key}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.airflow_fargate_alb[each.key].id]
  subnets            = var.subnets
  ip_address_type    = "ipv4"
}

# application load balancer tagret group
# this is where the network traffic is being routed to (the ecs container)
resource "aws_lb_target_group" "airflow_fargate" {
  for_each    = { for key, value in var.airflow_components : key => value if key == "webserver" }
  name        = "airflow-${each.key}"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    enabled             = true
    path                = "/health"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 5
  }
}


# application load balancer listener
# the listener routes traffic from the load balancer's dns name to the load balancer target group
resource "aws_lb_listener" "airflow_fargate_plain_http" {
  for_each = local.create_plain_http_listener ? { for key, value in var.airflow_components : key => value if key == "webserver" } : {}

  load_balancer_arn = aws_lb.airflow_fargate[each.key].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_fargate[each.key].arn
  }
}



####

resource "aws_lb_listener" "airflow_fargate_http" {
  for_each = local.create_http_listener ? { for key, value in var.airflow_components : key => value if key == "webserver" } : {}

  load_balancer_arn = aws_lb.airflow_fargate[each.key].id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_lb_listener" "airflow_fargate_https" {
  for_each = local.create_https_listener ? { for key, value in var.airflow_components : key => value if key == "webserver" } : {}

  load_balancer_arn = aws_lb.airflow_fargate[each.key].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = module.acm.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_fargate[each.key].arn
  }
}

# A subnet group for our RDS instance.
resource "aws_db_subnet_group" "airflow_metadata_db" {
  name       = "${var.rds_identifier}-subg"
  subnet_ids = var.subnets
}

locals {
  all_security_groups = concat(
    values(aws_security_group.airflow_fargate_service)[*].id,
  )
}

# A security group to attach to our RDS instance.
# It should allow incoming access on var.metadata_db.port from our airflow services.
resource "aws_security_group" "airflow_metadata_db" {
  name        = "${var.rds_identifier}-secg"
  description = "Allow inbound traffic to RDS from ECS"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = local.all_security_groups

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A postgres RDS instance for airflow metadata.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
resource "aws_db_instance" "airflow_metadata_db" {
  identifier                 = var.rds_identifier
  allocated_storage          = var.rds_allocated_storage
  max_allocated_storage      = var.rds_max_allocated_storage
  db_subnet_group_name       = aws_db_subnet_group.airflow_metadata_db.name
  engine                     = var.rds_engine
  engine_version             = var.rds_engine_version
  instance_class             = var.rds_instance_class
  kms_key_id                 = aws_kms_key.airflow_kms.arn
  storage_encrypted          = true
  deletion_protection        = var.rds_deletion_protection
  publicly_accessible        = var.rds_publicly_accessible
  auto_minor_version_upgrade = var.rds_auto_minor_version_upgrade
  vpc_security_group_ids     = [aws_security_group.airflow_metadata_db.id]
  apply_immediately          = true
  skip_final_snapshot        = true
  username                   = jsondecode(data.aws_secretsmanager_secret_version.airflow_metadata_db_secret_version.secret_string)["username"]
  password                   = jsondecode(data.aws_secretsmanager_secret_version.airflow_metadata_db_secret_version.secret_string)["password"]
  port                       = 5432
}

resource "aws_route53_zone" "airflow_zone" {
  count = length(var.route53_domain_name) > 0 ? 1 : 0
  name  = var.route53_domain_name
}

resource "aws_route53_record" "airflow_route53" {
  count   = length(var.route53_domain_name) > 0 && length(var.route53_dns_name) > 0 ? 1 : 0
  name    = var.route53_dns_name
  zone_id = aws_route53_zone.airflow_zone[0].zone_id
  type    = "A"

  alias {
    name                   = aws_lb.airflow_fargate.dns_name
    zone_id                = aws_lb.airflow_fargate.zone_id
    evaluate_target_health = true
  }
}

resource "aws_secretsmanager_secret" "airflow_metadata_db_secret" {
  name        = "variables/airflow_meta_db"
  description = "Credentials for the Airflow metadata RDS instance"
}

data "aws_secretsmanager_secret_version" "airflow_metadata_db_secret_version" {
  secret_id = aws_secretsmanager_secret.airflow_metadata_db_secret.id
}

# security group for application load balancer
# allow incoming traffic from port 80
resource "aws_security_group" "airflow_fargate_alb" {
  for_each    = { for key, value in var.airflow_components : key => value if key == "webserver" }
  name        = "airflow-${each.key}-alb-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


## security group for ecs service
resource "aws_security_group" "airflow_fargate_service" {
  for_each    = { for key, value in var.airflow_components : key => value }
  name        = "airflow-${each.key}-service-sg"
  description = "Allow HTTP inbound traffic from load balancer"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = each.key == "webserver" ? [each.value] : []
    content {
      description     = "HTTP from load balancer"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      security_groups = [aws_security_group.airflow_fargate_alb[each.key].id]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Specifies the AWS region where resources will be created.
variable "aws_region" {
  description = "The AWS region where infrastructure components will be provisioned."
  type        = string
  default     = "eu-central-1"
}

# Sets the retention period for logs in CloudWatch, in days.
variable "airflow_cloudwatch_retention" {
  description = "The number of days CloudWatch logs should be retained."
  type        = number
  default     = 7
}

# Cloudwatch log group prefix
variable "cloudwatch_log_prefix" {
  description = "The CloudWatch logs prefix."
  type        = string
  default     = "airflow-fargate"
}

# The unique identifier of the Virtual Private Cloud (VPC) where resources will be deployed.
variable "vpc_id" {
  description = "The ID of the Virtual Private Cloud (VPC) where resources are deployed."
  type        = string
}

# Specifies the subnets within the VPC.
variable "subnets" {
  description = "Subnet IDs within the VPC."
  type        = list(string)
}

# ECR repository name
variable "ecr_repository_name" {
  description = "The ECR repository name for the Docker image."
  type        = string
  default     = "airflow-fargate"
}

# ECS variables

# ECS cluster name
variable "ecs_cluster_name" {
  description = "The ECR repository name for the Docker image."
  type        = string
  default     = "airflow"
}

# Determines if all the ECS services and tasks should run on SPOT instances
variable "use_spot" {
  description = "Whether all the ECS services and tasks should run on SPOT intances"
  type        = bool
  default     = true
}

# Forces a new deployment of the ECS service when there are any changes.
variable "force_new_ecs_service_deployment" {
  description = "Forces a new deployment for the ECS service upon any changes."
  type        = bool
  default     = true
}

# Configuration for different Airflow components.
variable "airflow_components" {
  description = "Configuration settings for various Airflow components. Includes command, healthcheck, and desired count for each component."
  type = map(object({
    command       = optional(list(string))
    healthcheck   = optional(list(string))
    desired_count = optional(number)
  }))
}

# Allows for executing commands within the ECS container via AWS SSM.
variable "enable_execute_command" {
  description = "Allows executing commands in the ECS container via AWS SSM."
  type        = bool
  default     = true
}

# Custom environment variables for the Airflow application.
variable "airflow_environment_variables" {
  description = "List of custom environment variables to be set for the Airflow application."
  type = list(object({
    name  = string
    value = string
  }))
}

# Specifies the ECS capacity providers used in the cluster.
variable "capacity_providers" {
  description = "The capacity providers that are used for ECS tasks."
  type        = list(string)
  default     = ["FARGATE_SPOT", "FARGATE"]
}

# IAM role assumed by ECS to execute tasks for Airflow.
variable "airflow_ecs_role" {
  description = "IAM role assumed by ECS when executing Airflow tasks."
  type        = string
  default     = "role-ecs-task-execution"
}

# CPU units to assign to the ECS task.
variable "cpu" {
  description = "Number of CPU units to allocate for the ECS task."
  type        = number
  default     = 1024
}

# Amount of memory to assign to the ECS task, measured in MiB.
variable "memory" {
  description = "Amount of memory (in MiB) to allocate for the ECS task."
  type        = number
  default     = 2048
}

# Average CPU usage threshold to trigger ECS task auto-scaling.
variable "autoscale_cpu_avg_usage" {
  description = "CPU usage percentage that triggers ECS task autoscaling."
  type        = number
}

# Minimum number of ECS tasks to maintain when scaling in.
variable "min_capacity" {
  description = "Minimum number of ECS tasks to keep running when scaling in."
  type        = number
  default     = 1
}

# Maximum number of ECS tasks to run when scaling out.
variable "max_capacity" {
  description = "Maximum number of ECS tasks to run when scaling out."
  type        = number
  default     = 5
}

# RDS variables

# The unique identifier for the RDS instance. This identifier is used to distinguish different RDS instances.
variable "rds_identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string
  default     = "airflow-metadata-db"
}

# The initial storage allocated for the RDS instance, measured in gigabytes (GB).
variable "rds_allocated_storage" {
  description = "Initial storage size (in GB) allocated for the RDS instance."
  type        = number
  default     = 20
}

# The maximum storage that the RDS instance can scale up to, measured in gigabytes (GB).
variable "rds_max_allocated_storage" {
  description = "Maximum storage size (in GB) to which the RDS instance can scale."
  type        = number
  default     = 100
}

# The database engine to be used for the RDS instance.
variable "rds_engine" {
  description = "Database engine to use for the RDS instance."
  type        = string
  default     = "postgres"
}

# The version of the database engine to be used for the RDS instance.
variable "rds_engine_version" {
  description = "Version of the database engine for the RDS instance."
  type        = string
  default     = "15.4"
}

# The compute and memory capacity class for the RDS instance.
variable "rds_instance_class" {
  description = "Compute and memory capacity class for the RDS instance."
  type        = string
  default     = "db.t3.micro"
}

# Determines if the RDS instance is accessible publicly. If true, the RDS instance is accessible from the internet.
variable "rds_publicly_accessible" {
  description = "Whether the RDS instance should be publicly accessible from the internet."
  type        = bool
  default     = false
}

# Determines if minor engine upgrades will be applied to the RDS instance automatically during maintenance windows.
variable "rds_auto_minor_version_upgrade" {
  description = "Automatically apply minor engine upgrades during maintenance windows."
  type        = bool
  default     = true
}

# Determines if the RDS has deletion protected enabled.
variable "rds_deletion_protection" {
  description = "Enables or disables deletion protection on the RDS instance."
  type        = bool
  default     = true
}

# route53
# Route53 domain name.
variable "route53_domain_name" {
  description = "The domain name for Route 53"
  type        = bool
}

# Route53 record name.
variable "route53_dns_name" {
  description = "The dns record for Airflow"
  type        = bool
}
