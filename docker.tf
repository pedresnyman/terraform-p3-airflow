resource "docker_image" "airflow_image" {
  name         = "${aws_ecr_repository.airflow.repository_url}:latest"
  build {
    context    = var.docker_context_path
    dockerfile = var.dockerfile_path
  }
}