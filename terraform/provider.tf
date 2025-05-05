terraform {
  required_version = ">= 1.1"

  backend "s3" {
    bucket         = "todo-list-terraform-state-1234"
    key            = "todo-api/${terraform.workspace}.tfstate"
    region         = "us-east-1"

    # optional, but strongly recommended to avoid corruption:
    dynamodb_table = "todo-list-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
