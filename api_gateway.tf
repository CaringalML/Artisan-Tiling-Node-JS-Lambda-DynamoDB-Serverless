# API Gateway REST API
resource "aws_api_gateway_rest_api" "contact_api" {
  name        = "artisan-tiling-api"
  description = "API for Artisan Tiling contact form"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "artisan-tiling-api"
    Environment = var.environment
  }
}

# API Gateway Resource - root path
resource "aws_api_gateway_resource" "contact_resource" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  parent_id   = aws_api_gateway_rest_api.contact_api.root_resource_id
  path_part   = "contact"
}

# API Gateway Method - POST
resource "aws_api_gateway_method" "contact_method" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration - POST
resource "aws_api_gateway_integration" "contact_integration" {
  rest_api_id             = aws_api_gateway_rest_api.contact_api.id
  resource_id             = aws_api_gateway_resource.contact_resource.id
  http_method             = aws_api_gateway_method.contact_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

# API Gateway Method Response - POST 200
resource "aws_api_gateway_method_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_method.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# API Gateway Method - OPTIONS (for CORS)
resource "aws_api_gateway_method" "contact_options" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# API Gateway Integration - OPTIONS
resource "aws_api_gateway_integration" "contact_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# API Gateway Method Response - OPTIONS 200
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# API Gateway Integration Response - OPTIONS
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_options.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.domain_name}'"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.contact_integration,
    aws_api_gateway_integration.contact_options_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  
  # Add triggers to force redeployment when APIs change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.contact_resource.id,
      aws_api_gateway_method.contact_method.id,
      aws_api_gateway_integration.contact_integration.id,
      aws_api_gateway_method.contact_options.id,
      aws_api_gateway_integration.contact_options_integration.id,
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage Settings
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  stage_name    = "${var.environment}-v2"
  
  # Enable X-Ray tracing
  xray_tracing_enabled = true
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [deployment_id]
  }
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
  
  tags = {
    Environment = var.environment
  }
}

# Add method level throttling settings for the POST method
resource "aws_api_gateway_method_settings" "contact_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "${aws_api_gateway_resource.contact_resource.path_part}/${aws_api_gateway_method.contact_method.http_method}"
  
  settings {
    # Throttling settings
    throttling_rate_limit  = 10  # 10 requests per second
    throttling_burst_limit = 5   # Allow bursts of up to 5 requests
    
    # Enable detailed metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

# Add stage level throttling settings as a fallback (using method_settings with '*/*')
resource "aws_api_gateway_method_settings" "stage_throttling_settings" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"  # This applies to all methods in all resources
  
  settings {
    throttling_rate_limit  = 20  # 20 requests per second at stage level
    throttling_burst_limit = 10  # Allow bursts of up to 10 requests at stage level
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.contact_api.id}/${var.environment}"
  retention_in_days = 7
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for Throttling
resource "aws_cloudwatch_metric_alarm" "throttling_alarm" {
  alarm_name          = "api-throttling-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This alarm monitors API throttling (429 errors)"
  
  dimensions = {
    ApiName  = aws_api_gateway_rest_api.contact_api.name
    Stage    = aws_api_gateway_stage.api_stage.stage_name
    Resource = aws_api_gateway_resource.contact_resource.path
    Method   = aws_api_gateway_method.contact_method.http_method
  }
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}