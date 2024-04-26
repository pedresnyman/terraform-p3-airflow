# Module Overview
This Terraform module deploys Apache Airflow in AWS, utilizing ECS Fargate for orchestrating and running Airflow tasks. The module sets up the necessary infrastructure components, including VPC configuration, ECS services, RDS for metadata storage, CloudWatch for logging, and ALB for load balancing.

# Prerequisites
 - AWS Account
 - Terraform installed (version 1.8.1 or higher)
 - Configured AWS CLI with appropriate permissions
 - An existing VPC and subnet IDs (public and private)

## Input Variables

### Required Variables

These variables must be set in the module for it to operate correctly.

| Name | Description | Type |
|------|-------------|------|
| `vpc_id` | ID of the VPC where resources are deployed. | `string` |
| `public_subnet_ids` | List of public subnet IDs for the load balancer. | `list(string)` |
| `private_subnet_ids` | List of private subnet IDs for ECS tasks. | `list(string)` |

### Optional Variables

These variables are optional and have default values; customize them based on your requirements.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `airflow_username` | Username for the Airflow webserver. | `string` | `"airflow"` |
| `airflow_username_password` | Password for the Airflow user. If null, a password will be generated. | `string` | `null` |
| `aws_region` | AWS region where resources will be created. | `string` | `"eu-central-1"` |
| `airflow_cloudwatch_retention` | Number of days to retain CloudWatch logs. | `number` | `7` |
| `cloudwatch_log_prefix` | Prefix for CloudWatch log groups. | `string` | `"airflow-fargate"` |
| `ecr_repository_name` | Name of the ECR repository for Airflow Docker images. | `string` | `"airflow-fargate"` |
| `ecr_force_delete` | Determines whether to force delete the ECR repository, including all of its images, when the repository is destroyed. | `bool` | `true` |
| `ecs_cluster_name` | Name of the ECS cluster for deploying Airflow. | `string` | `"airflow"` |
| `use_spot` | Whether all the ECS services and tasks should run on SPOT instances. | `bool` | `true` |
| `force_new_ecs_service_deployment` | Forces a new deployment for the ECS service upon any changes. | `bool` | `true` |
| `enable_execute_command` | Allows executing commands in the ECS container via AWS SSM. | `bool` | `true` |
| `airflow_environment_variables` | List of custom environment variables to be set for the Airflow application. | `list(object({ name = string, value = string }))` | - |
| `capacity_providers` | Specifies the ECS capacity providers used in the cluster. | `list(string)` | `["FARGATE_SPOT", "FARGATE"]` |
| `airflow_ecs_role` | IAM role assumed by ECS when executing Airflow tasks. | `string` | `null` |
| `task_executor_cpu` | Number of CPU units to allocate for the task-executor ECS task. | `number` | `1024` |
| `task_executor_memory` | Amount of memory (in MiB) to allocate for the task-executor ECS task. | `number` | `2048` |
| `webserver_cpu` | Number of CPU units to allocate for the webserver ECS task. | `number` | `1024` |
| `webserver_memory` | Amount of memory (in MiB) to allocate for the webserver ECS task. | `number` | `2048` |
| `scheduler_cpu` | Number of CPU units to allocate for the scheduler ECS task. | `number` | `1024` |
| `scheduler_memory` | Amount of memory (in MiB) to allocate for the scheduler ECS task. | `number` | `2048` |
| `triggerer_cpu` | Number of CPU units to allocate for the triggerer ECS task. | `number` | `1024` |
| `triggerer_memory` | Amount of memory (in MiB) to allocate for the triggerer ECS task. | `number` | `2048` |
| `webserver_autoscale_cpu_avg_usage` | CPU usage percentage that triggers ECS task autoscaling for the webserver. | `number` | `70` |
| `scheduler_autoscale_cpu_avg_usage` | CPU usage percentage that triggers ECS task autoscaling for the scheduler. | `number` | `70` |
| `triggerer_autoscale_cpu_avg_usage` | CPU usage percentage that triggers ECS task autoscaling for the triggerer. | `number` | `70` |
| `webserver_autoscale_min_capacity` | Minimum number of webserver ECS tasks to maintain when scaling in. | `number` | `1` |
| `webserver_autoscale_max_capacity` | Maximum number of webserver ECS tasks to run when scaling out. | `number` | `5` |
| `scheduler_autoscale_min_capacity` | Minimum number of scheduler ECS tasks to maintain when scaling in. | `number` | `1` |
| `scheduler_autoscale_max_capacity` | Maximum number of scheduler ECS tasks to run when scaling out. | `number` | `5` |
| `triggerer_autoscale_min_capacity` | Minimum number of triggerer ECS tasks to maintain when scaling in. | `number` | `1` |
| `triggerer_autoscale_max_capacity` | Maximum number of triggerer ECS tasks to run when scaling out. | `number` | `5` |
| `webserver_count` | The number of webservers you want to configure. | `number` | `1` |
| `scheduler_count` | The number of schedulers you want to configure. | `number` | `1` |
| `triggerer_count` | The number of triggerers you want to configure. | `number` | `1` |
| `rds_database_name` | Database name for Airflow metadata storage. | `string` | `"airflow"` |
| `rds_identifier` | Unique identifier for the RDS instance. | `string` | `"airflow-metadata-db"` |
| `rds_allocated_storage` | Initial storage size (in GB) allocated for the RDS instance. | `number` | `20` |
| `rds_max_allocated_storage` | Maximum storage size (in GB) to which the RDS instance can scale. | `number` | `100` |
| `rds_engine` | Database engine to use for the RDS instance. | `string` | `"postgres"` |
| `rds_engine_version` | Version of the database engine for the RDS instance. | `string` | `"15.5"` |
| `rds_instance_class` | Compute and memory capacity class for the RDS instance. | `string` | `"db.t3.micro"` |
| `rds_publicly_accessible` | Whether the RDS instance should be publicly accessible from the internet. | `bool` | `false` |
| `rds_auto_minor_version_upgrade` | Automatically apply minor engine upgrades during maintenance windows. | `bool` | `true` |
| `rds_deletion_protection` | Enables or disables deletion protection on the RDS instance. | `bool` | `true` |
| `secrets_manager_recovery_window_in_days` | Amount of days to keep the secret after deletion in AWS Secrets Manager. | `number` | `0` |
| `load_balancer_internal_facing` | Specifies if the load balancer should be internal facing only. | `bool` | `false` |

This structure will guide users effectively, highlighting what they must configure and what options they have to further customize their deployment.


## Example Usage

```hcl
module "airflow_fargate" {
  source = "path/to/module"

  vpc_id               = "vpc-xxxxxxx"
  public_subnet_ids    = ["subnet-xxxxxxx", "subnet-yyyyyyy"]
  private_subnet_ids   = ["subnet-zzzzzzz", "subnet-aaaaaaa"]
  aws_region           = "eu-central-1"
  airflow_username     = "admin"
  airflow_username_password = "yourStrongPassword"
  cloudwatch_log_prefix = "my-airflow-logs"
  ecr_repository_name  = "my-airflow-repo"
}