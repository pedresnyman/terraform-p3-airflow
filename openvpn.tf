module "openvpn" {
  source  = "DNXLabs/openvpn/aws"
  version = "1.5.0"  # Use the latest version from the Terraform registry

  name                = "airflow-openvpn"
  vpc_id              = local.vpc_id
  public_subnet       = local.public_subnets[0]  # Deploy in one of your public subnets
  allowed_cidr_blocks = ["0.0.0.0/0"]  # Set this to your IP range for initial access

  # Additional configurations as needed...
}