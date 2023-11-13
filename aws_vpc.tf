module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  count = try(length(var.vpc_id), 0) == 0 ? 1 : 0

  name = "airflow-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_map_public_ip_on_launch = [true, true, true]

  tags = {
    Terraform = "true"
  }
}
