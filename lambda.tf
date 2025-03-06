# Lambda Function
resource "aws_lambda_function" "contact_form" {
  function_name    = var.lambda_function_name
  filename         = "lambda_function.zip"  # This should be your packaged Express.js app
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("lambda_function.zip")
  timeout          = 30
  memory_size      = 256
  
  # Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }
  
  environment {
    variables = {
      DYNAMODB_TABLE       = aws_dynamodb_table.contact_form.name
      INVENTORY_TABLE_NAME = aws_dynamodb_table.inventory.name
      ENVIRONMENT          = var.environment
      CORS_ORIGIN          = "https://${var.domain_name}"
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
  function_name = aws_lambda_function.contact_form.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.contact_api.execution_arn}/*/*"
}

# Update IAM role policies if needed - make sure permissions include inventory table
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "lambda_dynamodb_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Resource = [
          aws_dynamodb_table.contact_form.arn,
          aws_dynamodb_table.inventory.arn,
          "${aws_dynamodb_table.inventory.arn}/index/*"
        ],
        Effect = "Allow"
      }
    ]
  })
}