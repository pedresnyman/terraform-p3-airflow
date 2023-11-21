# application load balancer
# this allows us to have high availability
resource "aws_lb" "airflow_fargate" {
  for_each           = { for key, value in local.airflow_components : key => value if key == "webserver" }
  name               = "airflow-${each.key}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.airflow_fargate_alb[each.key].id]
  subnets            = local.subnet_ids
  ip_address_type    = "ipv4"
}

# application load balancer tagret group
# this is where the network traffic is being routed to (the ecs container)
resource "aws_lb_target_group" "airflow_fargate" {
  for_each    = { for key, value in local.airflow_components : key => value if key == "webserver" }
  name        = "airflow-${each.key}"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id
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
resource "aws_lb_listener" "airflow_fargate_plain_http" {
  for_each = { for key, value in local.airflow_components : key => value if key == "webserver" }

  load_balancer_arn = aws_lb.airflow_fargate[each.key].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_fargate[each.key].arn
  }
}
