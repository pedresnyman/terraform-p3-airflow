# create ecs services
# webserver, scheduler, triggerer
resource "aws_ecs_service" "airflow_fargate" {
  for_each        = { for k, v in local.airflow_components : k => v if k != "task-executor" }
  name            = "airflow-${each.key}"
  task_definition = aws_ecs_task_definition.airflow_fargate[each.key].family
  cluster         = aws_ecs_cluster.airflow.arn
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = each.value.desired_count
  enable_execute_command             = var.enable_execute_command
  network_configuration {
    subnets          = local.private_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.airflow_fargate_service[each.key].id]
  }
  capacity_provider_strategy {
    capacity_provider = var.use_spot ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
  }
  dynamic "load_balancer" {
    for_each = each.key == "webserver" ? [each.value] : []
    content {
      target_group_arn = aws_lb_target_group.airflow_fargate[each.key].arn
      container_name   = each.key
      container_port   = 8080
    }
  }
  platform_version     = "1.4.0"
  scheduling_strategy  = "REPLICA"
  force_new_deployment = var.force_new_ecs_service_deployment
}
