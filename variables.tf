variable "zone_id" {
  description = "The Route53 zone ID for artisantiling.co.nz domain"
  type        = string
}

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

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
  default     = "artisantiling.co.nz"
}

variable "api_domain_name" {
  description = "The domain name for the API"
  type        = string
  default     = "serverless.artisantiling.co.nz"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "artisan-tiling-contacts"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "artisan-tiling-contact-form"
}