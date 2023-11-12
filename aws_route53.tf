#resource "aws_route53_zone" "airflow_zone" {
#  count = length(var.route53_domain_name) > 0 ? 1 : 0
#  name  = var.route53_domain_name
#}
#
#resource "aws_route53_record" "airflow_route53" {
#  count   = length(var.route53_domain_name) > 0 && length(var.route53_dns_name) > 0 ? 1 : 0
#  name    = var.route53_dns_name
#  zone_id = aws_route53_zone.airflow_zone[0].zone_id
#  type    = "A"
#
#  alias {
#    name                   = aws_lb.airflow_fargate.dns_name
#    zone_id                = aws_lb.airflow_fargate.zone_id
#    evaluate_target_health = true
#  }
#}