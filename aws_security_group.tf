# security group for application load balancer
# allow incoming traffic from port 80
resource "aws_security_group" "airflow_fargate_alb" {
  #checkov:skip=CKV_AWS_260: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 80"
  #checkov:skip=CKV2_AWS_5
  #checkov:skip=CKV_AWS_23
  for_each    = { for key, value in var.airflow_components : key => value if key == "webserver" }
  name        = "airflow-${each.key}-alb-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = local.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


## security group for ecs service
resource "aws_security_group" "airflow_fargate_service" {
  #checkov:skip=CKV_AWS_23
  #checkov:skip=CKV2_AWS_5
  for_each    = { for key, value in var.airflow_components : key => value }
  name        = "airflow-${each.key}-service-sg"
  description = "Allow HTTP inbound traffic from load balancer"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = each.key == "webserver" ? [each.value] : []
    content {
      description     = "HTTP from load balancer"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      security_groups = [aws_security_group.airflow_fargate_alb[each.key].id]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
