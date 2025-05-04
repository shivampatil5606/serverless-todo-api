variable "env"        { type = string }
variable "lambda_arn" { type = string }

# 1) Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# 2) REST API & Resource & Method (unchanged)
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.env}-todo-api"
}
resource "aws_api_gateway_resource" "todos" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "todos"
}
resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.todos.id
  http_method   = "ANY"
  authorization = "NONE"
}

# 3) LAMBDA PERMISSION for API Gateway
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"

  # Only allow invocations from *this* API
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

# 4) PROXY Integration with the full ARN+path
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.todos.id
  http_method             = aws_api_gateway_method.any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  # <<< this must include the service:path/functions/.../invocations suffix >>>
  uri = format(
    "arn:aws:apigateway:%s:lambda:path/2015-03-31/functions/%s/invocations",
    data.aws_region.current.name,
    var.lambda_arn
  )
}

# 5) DEPLOYMENT + STAGE
resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  # force redeploy when integration changes
  triggers = {
    redeploy = sha1(jsonencode({
      methods      = aws_api_gateway_method.any.*.http_method
      integrations = aws_api_gateway_integration.lambda.*.uri
    }))
  }

  depends_on = [
    aws_api_gateway_integration.lambda
  ]
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = var.env
}

# 6) OUTPUT the invoke URL
output "invoke_url" {
  value = format(
    "https://%s.execute-api.%s.amazonaws.com/%s",
    aws_api_gateway_rest_api.api.id,
    data.aws_region.current.name,
    aws_api_gateway_stage.this.stage_name
  )
}

resource "aws_api_gateway_api_key" "key" {
  name    = "${var.env}-todo-key"
  enabled = true
}

output "api_key" {
  value = aws_api_gateway_api_key.key.value
}

resource "aws_api_gateway_usage_plan" "plan" {
  name = "${var.env}-todo-plan"
  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.this.stage_name
  }
}
resource "aws_api_gateway_usage_plan_key" "key" {
  key_id        = aws_api_gateway_api_key.key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan.id
}

