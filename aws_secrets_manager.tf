resource "aws_secretsmanager_secret" "airflow_metadata_db_secret" {
  #checkov:skip=CKV2_AWS_57
  #checkov:skip=CKV_AWS_149
  name        = "variables/airflow_meta_db"
  description = "Credentials for the Airflow metadata RDS instance"
}

data "aws_secretsmanager_secret_version" "airflow_metadata_db_secret_version" {
  secret_id = aws_secretsmanager_secret.airflow_metadata_db_secret.id
}
