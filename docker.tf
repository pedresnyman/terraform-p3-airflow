resource "docker_image" "airflow_image" {
  name         = "${aws_ecr_repository.airflow.repository_url}:latest"
  build {
    context    = var.docker_context_path
    dockerfile = var.dockerfile_path
  }
}

resource "null_resource" "ecr_login" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.airflow.repository_url}"
  }
}