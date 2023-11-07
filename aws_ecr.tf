# ecr repository for the airflow environment
resource "aws_ecr_repository" "airflow" {
  name = var.ecr_repository_name
  image_scanning_configuration {
    scan_on_push = true
  }
}
