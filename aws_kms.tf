# resource block for KMS key
resource "aws_kms_key" "airflow_kms" {
  description             = "KMS key for Airflow metadb"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}
