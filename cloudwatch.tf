# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.contact_api.id}/${var.environment}"
  retention_in_days = 14

  tags = {
    Environment = var.environment
    Service     = "API Gateway"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14

  tags = {
    Environment = var.environment
    Function    = var.lambda_function_name
  }
}

# CloudWatch Alarm for API Throttling (429 errors)
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

# CloudWatch Alarm for Inventory API Throttling
resource "aws_cloudwatch_metric_alarm" "inventory_throttling_alarm" {
  alarm_name          = "inventory-api-throttling-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This alarm monitors Inventory API throttling (429 errors)"
  
  dimensions = {
    ApiName  = aws_api_gateway_rest_api.contact_api.name
    Stage    = aws_api_gateway_stage.api_stage.stage_name
    Resource = aws_api_gateway_resource.inventory_resource.path
  }
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors_alarm" {
  alarm_name          = "${var.lambda_function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 2
  alarm_description   = "This alarm monitors Lambda function errors"
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for Lambda Duration (latency)
resource "aws_cloudwatch_metric_alarm" "lambda_duration_alarm" {
  alarm_name          = "${var.lambda_function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Average"
  threshold           = 3000  # 3 seconds in milliseconds
  alarm_description   = "This alarm monitors Lambda function execution time"
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for Lambda Throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_alarm" {
  alarm_name          = "${var.lambda_function_name}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This alarm monitors Lambda function throttling"
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for DynamoDB Throttling - Contact Form Table
resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle_alarm" {
  alarm_name          = "${var.dynamodb_table_name}-write-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This alarm monitors DynamoDB write throttling events for the contact form table"
  
  dimensions = {
    TableName = var.dynamodb_table_name
  }
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for DynamoDB Throttling - Inventory Table
resource "aws_cloudwatch_metric_alarm" "inventory_dynamodb_write_throttle_alarm" {
  alarm_name          = "${var.dynamodb_table_name}-inventory-write-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This alarm monitors DynamoDB write throttling events for the inventory table"
  
  dimensions = {
    TableName = "${var.dynamodb_table_name}-inventory"
  }
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}

# X-Ray Tracing - CloudWatch Dashboard for X-Ray Trace Metrics
resource "aws_cloudwatch_dashboard" "xray_dashboard" {
  dashboard_name = "${var.lambda_function_name}-xray-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/XRay", "TimeToFirstByte", "ServiceName", var.lambda_function_name, { stat = "Average" }],
            ["AWS/XRay", "Latency", "ServiceName", var.lambda_function_name, { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "X-Ray Trace Metrics - Response Time"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/XRay", "ErrorRate", "ServiceName", var.lambda_function_name, { stat = "Average" }],
            ["AWS/XRay", "FaultRate", "ServiceName", var.lambda_function_name, { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "X-Ray Trace Metrics - Error & Fault Rates"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/XRay", "ThrottleCount", "ServiceName", var.lambda_function_name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "X-Ray Trace Metrics - Throttle Count"
          period  = 300
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 12
        width  = 24
        height = 2
        properties = {
          markdown = "## X-Ray Tracing for API and Lambda\nThis dashboard provides key metrics from AWS X-Ray traces. For detailed trace analysis, visit the [X-Ray console](https://console.aws.amazon.com/xray/home)."
        }
      }
    ]
  })
}

# CloudWatch Log Metric Filter for Lambda Errors
resource "aws_cloudwatch_log_metric_filter" "lambda_error_metric" {
  name           = "${var.lambda_function_name}-error-filter"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name

  metric_transformation {
    name      = "${var.lambda_function_name}-log-errors"
    namespace = "CustomMetrics"
    value     = "1"
  }
}

# CloudWatch Alarm based on the custom error metric
resource "aws_cloudwatch_metric_alarm" "lambda_log_errors_alarm" {
  alarm_name          = "${var.lambda_function_name}-log-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.lambda_function_name}-log-errors"
  namespace           = "CustomMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors Lambda function log errors"
  
  alarm_actions = []  # Add SNS topic ARN if you want notifications
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Dashboard for Inventory Metrics
resource "aws_cloudwatch_dashboard" "inventory_dashboard" {
  dashboard_name = "inventory-metrics-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", aws_api_gateway_rest_api.contact_api.name, "Resource", aws_api_gateway_resource.inventory_resource.path, "Method", "GET", "Stage", aws_api_gateway_stage.api_stage.stage_name],
            ["AWS/ApiGateway", "Count", "ApiName", aws_api_gateway_rest_api.contact_api.name, "Resource", aws_api_gateway_resource.inventory_resource.path, "Method", "POST", "Stage", aws_api_gateway_stage.api_stage.stage_name],
            ["...", "${aws_api_gateway_resource.inventory_item_resource.path}", "Method", "GET"],
            ["...", "${aws_api_gateway_resource.inventory_item_resource.path}", "Method", "PUT"],
            ["...", "${aws_api_gateway_resource.inventory_item_resource.path}", "Method", "DELETE"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Inventory API Request Count"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", aws_api_gateway_rest_api.contact_api.name, "Resource", aws_api_gateway_resource.inventory_resource.path, "Stage", aws_api_gateway_stage.api_stage.stage_name],
            ["...", "${aws_api_gateway_resource.inventory_item_resource.path}"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Inventory API Latency"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiName", aws_api_gateway_rest_api.contact_api.name, "Resource", aws_api_gateway_resource.inventory_resource.path, "Stage", aws_api_gateway_stage.api_stage.stage_name],
            ["...", "${aws_api_gateway_resource.inventory_item_resource.path}"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Inventory API 4XX Errors"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "5XXError", "ApiName", aws_api_gateway_rest_api.contact_api.name, "Resource", aws_api_gateway_resource.inventory_resource.path, "Stage", aws_api_gateway_stage.api_stage.stage_name],
            ["...", "${aws_api_gateway_resource.inventory_item_resource.path}"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Inventory API 5XX Errors"
          period  = 300
        }
      }
    ]
  })
}