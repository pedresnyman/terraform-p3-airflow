# A subnet group for our RDS instance.
resource "aws_db_subnet_group" "airflow_metadata_db" {
  name       = "${var.rds_identifier}-subg"
  subnet_ids = local.private_subnet_ids
}

locals {
  all_security_groups = concat(
    values(aws_security_group.airflow_fargate_service)[*].id,
  )
}

# A security group to attach to our RDS instance.
# It should allow incoming access on var.metadata_db.port from our airflow services.
resource "aws_security_group" "airflow_metadata_db" {
  name        = "${var.rds_identifier}-secg"
  description = "Allow inbound traffic to RDS from ECS"
  vpc_id      = local.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = local.all_security_groups

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A postgres RDS instance for airflow metadata.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
resource "aws_db_instance" "airflow_metadata_db" {
  db_name                    = var.rds_database_name
  identifier                 = var.rds_identifier
  allocated_storage          = var.rds_allocated_storage
  max_allocated_storage      = var.rds_max_allocated_storage
  db_subnet_group_name       = aws_db_subnet_group.airflow_metadata_db.name
  engine                     = var.rds_engine
  engine_version             = var.rds_engine_version
  instance_class             = var.rds_instance_class
  kms_key_id                 = aws_kms_key.airflow_kms.arn
  storage_encrypted          = true
  deletion_protection        = var.rds_deletion_protection
  publicly_accessible        = var.rds_publicly_accessible
  auto_minor_version_upgrade = var.rds_auto_minor_version_upgrade
  vpc_security_group_ids     = [aws_security_group.airflow_metadata_db.id]
  apply_immediately          = true
  skip_final_snapshot        = true
  username                   = var.airflow_username
  password                   = var.airflow_username_password != null ? var.airflow_username_password : random_password.password[0].result
  port                       = 5432
}
