output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.api_stage.stage_name}/inventory"
}

output "api_health_url" {
  description = "Health check URL of the API Gateway"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.api_stage.stage_name}/health"
}

output "inventory_table_name" {
  description = "Name of the Inventory DynamoDB table"
  value       = aws_dynamodb_table.inventory.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.inventory_function.function_name
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.inventory_api.id
}