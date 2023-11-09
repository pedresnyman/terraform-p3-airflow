locals {
  create_route53_resources = length(var.route53_domain_name) > 0 && length(var.route53_dns_name) > 0
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
resource "aws_lb_listener" "airflow_fargate_http_default" {
  # This will become an empty map if create_route53_resources is true, thus not creating any resources.
  for_each = local.create_route53_resources ? {} : { for key, value in var.airflow_components : key => value if key == "webserver" }

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
  for_each = length(var.route53_domain_name) > 0 && length(var.route53_dns_name) > 0
             ? { for key, value in var.airflow_components : key => value if key == "webserver" }
             : {}

  load_balancer_arn = aws_lb.airflow_fargate[each.key].arn
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
  for_each = length(var.route53_domain_name) > 0 && length(var.route53_dns_name) > 0
             ? { for key, value in var.airflow_components : key => value if key == "webserver" }
             : {}

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

