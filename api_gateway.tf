# API Gateway REST API
resource "aws_api_gateway_rest_api" "contact_api" {
  name        = "artisan-tiling-api"
  description = "API for Artisan Tiling contact form and inventory management"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "artisan-tiling-api"
    Environment = var.environment
  }
}

# ----------------- Contact Form API Resources -----------------

# API Gateway Resource - contact path
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

# ----------------- Inventory API Resources -----------------

# API Gateway Resource - inventory path
resource "aws_api_gateway_resource" "inventory_resource" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  parent_id   = aws_api_gateway_rest_api.contact_api.root_resource_id
  path_part   = "inventory"
}

# API Gateway Resource - inventory/{id} path
resource "aws_api_gateway_resource" "inventory_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  parent_id   = aws_api_gateway_resource.inventory_resource.id
  path_part   = "{id}"
}

# CREATE - POST /inventory
resource "aws_api_gateway_method" "inventory_post" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.inventory_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "inventory_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.contact_api.id
  resource_id             = aws_api_gateway_resource.inventory_resource.id
  http_method             = aws_api_gateway_method.inventory_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

# READ ALL - GET /inventory
resource "aws_api_gateway_method" "inventory_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.inventory_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "inventory_get_all_integration" {
  rest_api_id             = aws_api_gateway_rest_api.contact_api.id
  resource_id             = aws_api_gateway_resource.inventory_resource.id
  http_method             = aws_api_gateway_method.inventory_get_all.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

# READ SINGLE - GET /inventory/{id}
resource "aws_api_gateway_method" "inventory_get_single" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.inventory_item_resource.id
  http_method   = "GET"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "inventory_get_single_integration" {
  rest_api_id             = aws_api_gateway_rest_api.contact_api.id
  resource_id             = aws_api_gateway_resource.inventory_item_resource.id
  http_method             = aws_api_gateway_method.inventory_get_single.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

# UPDATE - PUT /inventory/{id}
resource "aws_api_gateway_method" "inventory_put" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.inventory_item_resource.id
  http_method   = "PUT"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "inventory_put_integration" {
  rest_api_id             = aws_api_gateway_rest_api.contact_api.id
  resource_id             = aws_api_gateway_resource.inventory_item_resource.id
  http_method             = aws_api_gateway_method.inventory_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

# DELETE - DELETE /inventory/{id}
resource "aws_api_gateway_method" "inventory_delete" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.inventory_item_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "inventory_delete_integration" {
  rest_api_id             = aws_api_gateway_rest_api.contact_api.id
  resource_id             = aws_api_gateway_resource.inventory_item_resource.id
  http_method             = aws_api_gateway_method.inventory_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

# OPTIONS for /inventory (CORS support)
resource "aws_api_gateway_method" "inventory_options" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.inventory_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "inventory_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.inventory_resource.id
  http_method = aws_api_gateway_method.inventory_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "inventory_options_200" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.inventory_resource.id
  http_method = aws_api_gateway_method.inventory_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "inventory_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.inventory_resource.id
  http_method = aws_api_gateway_method.inventory_options.http_method
  status_code = aws_api_gateway_method_response.inventory_options_200.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.domain_name}'"
  }
}

# OPTIONS for /inventory/{id} (CORS support)
resource "aws_api_gateway_method" "inventory_item_options" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.inventory_item_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "inventory_item_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.inventory_item_resource.id
  http_method = aws_api_gateway_method.inventory_item_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "inventory_item_options_200" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.inventory_item_resource.id
  http_method = aws_api_gateway_method.inventory_item_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "inventory_item_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.inventory_item_resource.id
  http_method = aws_api_gateway_method.inventory_item_options.http_method
  status_code = aws_api_gateway_method_response.inventory_item_options_200.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,DELETE,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.domain_name}'"
  }
}

# ----------------- Deployment and Stage Settings -----------------

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    # Contact form endpoints
    aws_api_gateway_integration.contact_integration,
    aws_api_gateway_integration.contact_options_integration,
    
    # Inventory endpoints
    aws_api_gateway_integration.inventory_post_integration,
    aws_api_gateway_integration.inventory_get_all_integration,
    aws_api_gateway_integration.inventory_get_single_integration,
    aws_api_gateway_integration.inventory_put_integration,
    aws_api_gateway_integration.inventory_delete_integration,
    aws_api_gateway_integration.inventory_options_integration,
    aws_api_gateway_integration.inventory_item_options_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  
  # Add triggers to force redeployment when APIs change
  triggers = {
    redeployment = sha1(jsonencode([
      # Contact form resources
      aws_api_gateway_resource.contact_resource.id,
      aws_api_gateway_method.contact_method.id,
      aws_api_gateway_integration.contact_integration.id,
      aws_api_gateway_method.contact_options.id,
      aws_api_gateway_integration.contact_options_integration.id,
      
      # Inventory resources
      aws_api_gateway_resource.inventory_resource.id,
      aws_api_gateway_resource.inventory_item_resource.id,
      aws_api_gateway_method.inventory_post.id,
      aws_api_gateway_integration.inventory_post_integration.id,
      aws_api_gateway_method.inventory_get_all.id,
      aws_api_gateway_integration.inventory_get_all_integration.id,
      aws_api_gateway_method.inventory_get_single.id,
      aws_api_gateway_integration.inventory_get_single_integration.id,
      aws_api_gateway_method.inventory_put.id,
      aws_api_gateway_integration.inventory_put_integration.id,
      aws_api_gateway_method.inventory_delete.id,
      aws_api_gateway_integration.inventory_delete_integration.id,
      aws_api_gateway_method.inventory_options.id,
      aws_api_gateway_integration.inventory_options_integration.id,
      aws_api_gateway_method.inventory_item_options.id,
      aws_api_gateway_integration.inventory_item_options_integration.id
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
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
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

# Add method level throttling settings for the Contact POST method
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

# Add method level throttling settings for specific Inventory methods
# GET all inventory items
resource "aws_api_gateway_method_settings" "inventory_get_all_settings" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "${aws_api_gateway_resource.inventory_resource.path_part}/${aws_api_gateway_method.inventory_get_all.http_method}"
  
  settings {
    # Throttling settings
    throttling_rate_limit  = 15  # 15 requests per second for inventory operations
    throttling_burst_limit = 8   # Allow bursts of up to 8 requests
    
    # Enable detailed metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

# POST new inventory item
resource "aws_api_gateway_method_settings" "inventory_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "${aws_api_gateway_resource.inventory_resource.path_part}/${aws_api_gateway_method.inventory_post.http_method}"
  
  settings {
    # Throttling settings
    throttling_rate_limit  = 10  # 10 requests per second for inventory operations
    throttling_burst_limit = 5   # Allow bursts of up to 5 requests
    
    # Enable detailed metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

# GET single inventory item
resource "aws_api_gateway_method_settings" "inventory_get_single_settings" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "${aws_api_gateway_resource.inventory_item_resource.path_part}/${aws_api_gateway_method.inventory_get_single.http_method}"
  
  settings {
    # Throttling settings
    throttling_rate_limit  = 20  # 20 requests per second for individual item retrieval
    throttling_burst_limit = 10  # Allow bursts of up to 10 requests
    
    # Enable detailed metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

# PUT update inventory item
resource "aws_api_gateway_method_settings" "inventory_put_settings" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "${aws_api_gateway_resource.inventory_item_resource.path_part}/${aws_api_gateway_method.inventory_put.http_method}"
  
  settings {
    # Throttling settings
    throttling_rate_limit  = 10  # 10 requests per second
    throttling_burst_limit = 5   # Allow bursts of up to 5 requests
    
    # Enable detailed metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

# DELETE inventory item
resource "aws_api_gateway_method_settings" "inventory_delete_settings" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "${aws_api_gateway_resource.inventory_item_resource.path_part}/${aws_api_gateway_method.inventory_delete.http_method}"
  
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

