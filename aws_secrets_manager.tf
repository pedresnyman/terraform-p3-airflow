resource "aws_secretsmanager_secret" "airflow_metadata_db_secret" {
  name        = "variables/airflow_meta_db"
  description = "Credentials for the Airflow metadata RDS instance"
}

data "aws_secretsmanager_secret_version" "airflow_metadata_db_secret_version" {
  secret_id = aws_secretsmanager_secret.airflow_metadata_db_secret.id
}
