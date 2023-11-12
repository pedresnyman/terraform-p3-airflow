terraform {
  required_version = ">= 1.6.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}

data "aws_caller_identity" "this_account" {}
