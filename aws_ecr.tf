# ecr repository for the airflow environment
resource "aws_ecr_repository" "airflow" {
  #checkov:skip=CKV_AWS_136
  #checkov:skip=CKV_AWS_51
  name = "airflow-fargate"
  image_scanning_configuration {
    scan_on_push = true
  }
}
