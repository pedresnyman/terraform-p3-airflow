resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "airflow_metadata_db_secret" {
  name        = "variables/airflow_meta_db"
  description = "Credentials for the Airflow metadata RDS instance"
}

resource "aws_secretsmanager_secret_version" "airflow_metadata_db_secret_version" {
  secret_id     = aws_secretsmanager_secret.airflow_metadata_db_secret.id
  secret_string = jsonencode({
    password = random_password.password.result
  })
}
