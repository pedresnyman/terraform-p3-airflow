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
