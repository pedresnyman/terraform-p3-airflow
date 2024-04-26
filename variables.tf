# The Airflow username
variable "airflow_username" {
  description = "The Airflow username"
  type        = string
  default     = "airflow"
}

# The Airflow username password
variable "airflow_username_password" {
  description = "The Airflow username password"
  type        = string
  default     = null
  sensitive   = true
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

# Specifies the public subnet id's Airflow would be deployed.
variable "public_subnet_ids" {
  description = "Subnet IDs to deploy Airflow."
  type        = list(string)
}

# Specifies the private subnet id's Airflow would be deployed.
variable "private_subnet_ids" {
  description = "Subnet IDs to deploy Airflow."
  type        = list(string)
}

# ECR repository name
variable "ecr_repository_name" {
  description = "The ECR repository name for the Docker image."
  type        = string
  default     = "airflow-fargate"
}

# ECR force delete repository
variable "ecr_force_delete" {
  description = "Determines whether to force delete the ECR repository, including all of its images, when the repository is destroyed. Setting this to true will delete all images in the repository and the repository itself. Use with caution as this is irreversible."
  type        = bool
  default     = true
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

variable "execution_role_arn" {
  description = "ARN of the IAM role that ECS tasks assume for operations like pulling container images from ECR and publishing logs to CloudWatch. This role is used by the ECS agent during the setup and teardown of containers."
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the IAM role that the Airflow application running within the ECS task assumes to interact with AWS services directly, such as accessing S3 buckets or interfacing with RDS databases. This role provides AWS service permissions directly to the applications running on the ECS tasks."
  type        = string
}

# CPU units to assign to the ECS task.
variable "task_executor_cpu" {
  description = "Number of CPU units to allocate for the task-executor ECS task."
  type        = number
  default     = 1024
}

# Amount of memory to assign to the ECS task, measured in MiB.
variable "task_executor_memory" {
  description = "Amount of memory (in MiB) to allocate for the task-executor ECS task."
  type        = number
  default     = 2048
}

# CPU units to assign to the ECS task.
variable "webserver_cpu" {
  description = "Number of CPU units to allocate for the webserver ECS task."
  type        = number
  default     = 1024
}

# Amount of memory to assign to the ECS task, measured in MiB.
variable "webserver_memory" {
  description = "Amount of memory (in MiB) to allocate for the webserver ECS task."
  type        = number
  default     = 2048
}

# CPU units to assign to the ECS task.
variable "scheduler_cpu" {
  description = "Number of CPU units to allocate for the scheduler ECS task."
  type        = number
  default     = 1024
}

# Amount of memory to assign to the ECS task, measured in MiB.
variable "scheduler_memory" {
  description = "Amount of memory (in MiB) to allocate for the scheduler ECS task."
  type        = number
  default     = 2048
}

# CPU units to assign to the ECS task.
variable "triggerer_cpu" {
  description = "Number of CPU units to allocate for the triggerer ECS task."
  type        = number
  default     = 1024
}

# Amount of memory to assign to the ECS task, measured in MiB.
variable "triggerer_memory" {
  description = "Amount of memory (in MiB) to allocate for the triggerer ECS task."
  type        = number
  default     = 2048
}

# Average CPU usage threshold to trigger ECS task auto-scaling.
variable "webserver_autoscale_cpu_avg_usage" {
  description = "CPU usage percentage that triggers ECS task autoscaling."
  type        = number
  default     = 70
}

# Average CPU usage threshold to trigger ECS task auto-scaling.
variable "scheduler_autoscale_cpu_avg_usage" {
  description = "CPU usage percentage that triggers ECS task autoscaling."
  type        = number
  default     = 70
}

# Average CPU usage threshold to trigger ECS task auto-scaling.
variable "triggerer_autoscale_cpu_avg_usage" {
  description = "CPU usage percentage that triggers ECS task autoscaling."
  type        = number
  default     = 70
}

# Minimum number of webserver ECS tasks to maintain when scaling in.
variable "webserver_autoscale_min_capacity" {
  description = "Minimum number of ECS tasks to keep running when scaling in."
  type        = number
  default     = 1
}

# Maximum number of webserver ECS tasks to run when scaling out.
variable "webserver_autoscale_max_capacity" {
  description = "Maximum number of ECS tasks to run when scaling out."
  type        = number
  default     = 5
}

# Minimum number of scheduler ECS tasks to maintain when scaling in.
variable "scheduler_autoscale_min_capacity" {
  description = "Minimum number of ECS tasks to keep running when scaling in."
  type        = number
  default     = 1
}

# Maximum number of scheduler ECS tasks to run when scaling out.
variable "scheduler_autoscale_max_capacity" {
  description = "Maximum number of ECS tasks to run when scaling out."
  type        = number
  default     = 5
}

# Minimum number of triggerer ECS tasks to maintain when scaling in.
variable "triggerer_autoscale_min_capacity" {
  description = "Minimum number of ECS tasks to keep running when scaling in."
  type        = number
  default     = 1
}

# Maximum number of triggerer ECS tasks to run when scaling out.
variable "triggerer_autoscale_max_capacity" {
  description = "Maximum number of ECS tasks to run when scaling out."
  type        = number
  default     = 5
}

# The amount of Airflow webservers
variable "webserver_count" {
  description = "The number of webservers you want to configure"
  type        = number
  default     = 1
}

# The amount of Airflow schedulers
variable "scheduler_count" {
  description = "The number of schedulers you want to configure"
  type        = number
  default     = 1
}

# The amount of Airflow triggerer
variable "triggerer_count" {
  description = "The number of triggerers you want to configure"
  type        = number
  default     = 1
}

# RDS variables
# The name of the RDS database that will be used for Airflow
variable "rds_database_name" {
  description = "Database name for Airflow"
  type        = string
  default     = "airflow"
}

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
  default     = "15.5"
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

# secretsmanager
variable "secrets_manager_recovery_window_in_days" {
  description = "Amount of days to keep the secret after deletion"
  type        = number
  default     = 0 # force delete
}

variable "load_balancer_internal_facing" {
  type    = bool
  default = false
}
