resource "aws_route53_record" "airflow_fargate_route53" {
  for_each = { for key, value in var.airflow_components : key => value if lookup(value, "route53", null) != null }
  name     = each.value.route53
  zone_id  = var.route53_zone_id
  type     = "A"

  alias {
    name                   = aws_lb.airflow_fargate[each.key].dns_name
    zone_id                = aws_lb.airflow_fargate[each.key].zone_id
    evaluate_target_health = true
  }
}
