variable "env"           { type = string }
variable "zip_path"      { type = string }
variable "dynamodb_table"{ type = string }
variable "dynamodb_table_arn" { type = string }

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "dynamodb" {
  name = "${var.env}-dynamo-policy"
  role = aws_iam_role.exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = [
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      Effect   = "Allow"
      Resource = var.dynamodb_table_arn
    }]
  })
}

resource "aws_iam_role" "exec" {
  name               = "${var.env}-lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "todo" {
  function_name = "${var.env}-todo-fn"
  runtime       = "python3.9"
  role          = aws_iam_role.exec.arn
  handler       = "todo_handler.lambda_handler"
  filename      = var.zip_path
  source_code_hash = filebase64sha256(var.zip_path)
  environment {
    variables = {
      TABLE = var.dynamodb_table
    }
  }
  tags = { Environment = var.env }
}

output "lambda_arn" {
  value = aws_lambda_function.todo.arn
}
