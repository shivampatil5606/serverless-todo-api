variable "env" { type = string }

resource "aws_dynamodb_table" "todos" {
  name         = "${var.env}-todos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
  tags = { Environment = var.env }
}

output "table_name" {
  value = aws_dynamodb_table.todos.name
}

output "table_arn" {
  value = aws_dynamodb_table.todos.arn
}

