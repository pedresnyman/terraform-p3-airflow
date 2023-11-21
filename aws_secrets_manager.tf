resource "random_password" "password" {
  count  = var.airflow_username_password != null ? 0 : 1
  length = 16

  # Define allowed characters
  override_special = "!#$%&*+-=?^_{}~"

  # Ensure no problematic characters are included
  special = true
}

resource "aws_secretsmanager_secret" "airflow_metadata_db_secret" {
  name                    = "variables/airflow_meta_db"
  description             = "Credentials for the Airflow metadata RDS instance"
  recovery_window_in_days = var.secrets_manager_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "airflow_metadata_db_secret_version" {
  secret_id = aws_secretsmanager_secret.airflow_metadata_db_secret.id
  secret_string = jsonencode({
    password = var.airflow_username_password != null ? var.airflow_username_password : random_password.password[0].result
  })
}