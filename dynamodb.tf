resource "aws_dynamodb_table" "contact_form" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = var.dynamodb_table_name
    Environment = var.environment
  }

   # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = false // Enable point-in-time recovery if needed
  }
}