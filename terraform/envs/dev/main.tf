module "dynamodb" {
  source = "../../modules/dynamodb"
  env    = var.environment
}

module "lambda" {
  source             = "../../modules/lambda"
  env                = var.environment
  zip_path           = "../../../build/todo.zip"
  dynamodb_table     = module.dynamodb.table_name
  dynamodb_table_arn = module.dynamodb.table_arn
}


module "apigw" {
  source     = "../../modules/apigw"
  env        = var.environment
  lambda_arn = module.lambda.lambda_arn
}

# Expose the invoke_url and api_key from the apigw module in the root module
output "invoke_url" {
  description = "Base URL for our To-Do API"
  value       = module.apigw.invoke_url
}

output "api_key" {
  description = "The API key used to invoke the To-Do API"
  value       = module.apigw.api_key
  sensitive   = true
}

