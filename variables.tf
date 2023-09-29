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

# ECS variables

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
  description = "Configuration settings for various Airflow components. Includes command, healthcheck, desired count, and route53 settings for each component."
  type = map(object({
    command       = optional(list(string))
    healthcheck   = optional(list(string))
    desired_count = optional(number)
    route53       = optional(string)
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
  default     = "role-ecs-task-execution-2"
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
