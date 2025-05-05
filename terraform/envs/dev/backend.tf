terraform {
  backend "s3" {
    bucket = "todo-list-terraform-state-1234"
    key    = "todo-api/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "todo-list-terraform-locks"
    encrypt        = true
  }
}
