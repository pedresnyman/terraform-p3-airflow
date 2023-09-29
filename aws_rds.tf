# A subnet group for our RDS instance.
resource "aws_db_subnet_group" "airflow_metadata_db" {
  name       = "${var.rds_identifier}-subg"
  subnet_ids = var.private_subnets
}

locals {
  all_security_groups = concat(
    values(aws_security_group.airflow_fargate_service)[*].id,
  )
}

# A security group to attach to our RDS instance.
# It should allow incoming access on var.metadata_db.port from our airflow services.
resource "aws_security_group" "airflow_metadata_db" {
  #checkov:skip=CKV_AWS_23
  name        = "${var.rds_identifier}-secg"
  description = "Allow inbound traffic to RDS from ECS"
  vpc_id      = var.vpc_id
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
  #checkov:skip=CKV_AWS_161: "Ensure RDS database has IAM authentication enabled"
  #checkov:skip=CKV_AWS_353: "Ensure that RDS instances have performance insights enabled"
  #checkov:skip=CKV_AWS_157: "Ensure that RDS instances have Multi-AZ enabled"
  #checkov:skip=CKV_AWS_129: "Ensure that respective logs of Amazon Relational Database Service (Amazon RDS) are enabled"
  #checkov:skip=CKV_AWS_17: "Ensure all data stored in RDS is not publicly accessible"
  #checkov:skip=CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances"
  #checkov:skip=CKV2_AWS_60: "Ensure RDS instance with copy tags to snapshots is enabled"
  #checkov:skip=CKV2_AWS_30: "Ensure Postgres RDS as aws_db_instance has Query Logging enabled"
  #checkov:skip=CKV_AWS_354: "Ensure RDS Performance Insights are encrypted using KMS CMKs"
  identifier                 = var.rds_identifier
  allocated_storage          = var.rds_allocated_storage
  max_allocated_storage      = var.rds_max_allocated_storage
  db_subnet_group_name       = aws_db_subnet_group.airflow_metadata_db.name
  engine                     = var.rds_engine
  engine_version             = var.rds_engine_version
  instance_class             = var.rds_instance_class
  kms_key_id                 = aws_kms_key.airflow_kms.arn
  storage_encrypted          = true
  deletion_protection        = true
  publicly_accessible        = var.rds_publicly_accessible
  auto_minor_version_upgrade = var.rds_auto_minor_version_upgrade
  vpc_security_group_ids     = [aws_security_group.airflow_metadata_db.id]
  apply_immediately          = true
  skip_final_snapshot        = true
  username                   = jsondecode(data.aws_secretsmanager_secret_version.airflow_metadata_db_secret_version.secret_string)["username"]
  password                   = jsondecode(data.aws_secretsmanager_secret_version.airflow_metadata_db_secret_version.secret_string)["password"]
  port                       = 5432
}
