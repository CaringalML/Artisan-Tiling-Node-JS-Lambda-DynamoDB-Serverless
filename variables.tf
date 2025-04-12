variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"  # Sydney region, appropriate for New Zealand
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "cors_origin" {
  description = "Allowed origin for CORS"
  type        = string
  # default     = "*"
  default     = "https://inventory-manager-react-43791.web.app"
}

variable "inventory_table_name" {
  description = "Name of the inventory DynamoDB table"
  type        = string
  default     = "cloudstruct-inventory"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "cloudstruct-inventory-api"
}

variable "api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
  default     = "cloudstruct-inventory-api"
}

variable "api_description" {
  description = "Description of the API Gateway REST API"
  type        = string
  default     = "API for CloudStruct inventory management"
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda function in MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 30
}

variable "lambda_runtime" {
  description = "Runtime for Lambda function"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_handler" {
  description = "Handler for Lambda function"
  type        = string
  default     = "index.handler"
}

variable "lambda_zip_file" {
  description = "Path to Lambda function zip file"
  type        = string
  default     = "lambda_function.zip"
}

variable "cloudwatch_logs_retention" {
  description = "Retention period for CloudWatch Logs in days"
  type        = number
  default     = 14
}

variable "api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "v2"
}

variable "dynamodb_replica_regions" {
  description = "List of AWS regions for DynamoDB global table replicas"
  type        = list(string)
  default     = ["eu-west-2"]  # London region
}

variable "api_throttling" {
  description = "Default throttling settings for API Gateway"
  type = object({
    rate_limit  = number
    burst_limit = number
  })
  default = {
    rate_limit  = 20
    burst_limit = 10
  }
}

variable "method_throttling" {
  description = "Throttling settings for specific API methods"
  type = map(object({
    rate_limit  = number
    burst_limit = number
  }))
  default = {
    get_all = {
      rate_limit  = 15
      burst_limit = 8
    },
    post = {
      rate_limit  = 10
      burst_limit = 5
    },
    get_single = {
      rate_limit  = 20
      burst_limit = 10
    },
    put = {
      rate_limit  = 10
      burst_limit = 5
    },
    delete = {
      rate_limit  = 10
      burst_limit = 5
    }
  }
}

variable "alarm_thresholds" {
  description = "Thresholds for CloudWatch alarms"
  type = object({
    api_throttling    = number
    lambda_errors     = number
    lambda_duration   = number
    lambda_throttles  = number
    dynamodb_throttle = number
  })
  default = {
    api_throttling    = 10
    lambda_errors     = 2
    lambda_duration   = 3000
    lambda_throttles  = 1
    dynamodb_throttle = 1
  }
}