# resource block for KMS key
resource "aws_kms_key" "airflow_kms" {
  #checkov:skip=CKV2_AWS_64: "Ensure KMS key Policy is defined"
  description             = "KMS key for Airflow metadb"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}
