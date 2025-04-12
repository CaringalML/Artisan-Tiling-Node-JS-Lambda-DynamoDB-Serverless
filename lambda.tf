# Lambda Function
resource "aws_lambda_function" "inventory_function" {
  function_name    = var.lambda_function_name
  filename         = var.lambda_zip_file
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256(var.lambda_zip_file)
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  
  # Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }
  
  environment {
    variables = {
      INVENTORY_TABLE_NAME = aws_dynamodb_table.inventory.name
      ENVIRONMENT          = var.environment
      CORS_ORIGIN          = var.cors_origin
    }
  }
  
  tags = {
    Name        = var.lambda_function_name
    Environment = var.environment
  }
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventory_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.inventory_api.execution_arn}/*/*"
}