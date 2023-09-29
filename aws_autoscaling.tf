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
