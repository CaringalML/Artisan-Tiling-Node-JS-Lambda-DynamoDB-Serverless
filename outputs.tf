output "api_gateway_url" {
  description = "Default URL of the API Gateway"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_resource.contact_resource.path}"
}

output "custom_domain_url" {
  description = "Custom domain URL"
  value       = "https://${var.api_domain_name}/contact"
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.contact_form.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.contact_form.function_name
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.contact_api.id
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.api_cert.arn
}