module "acm" {
  count      = try(length(var.route53_domain_name), 0) > 0 ? 1 : 0
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