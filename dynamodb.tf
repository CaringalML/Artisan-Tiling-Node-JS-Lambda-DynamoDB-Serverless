# Inventory DynamoDB Table
resource "aws_dynamodb_table" "inventory" {
  name           = var.inventory_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  # Category attribute for GSI
  attribute {
    name = "category"
    type = "S"
  }
  
  # Global Secondary Index for category
  global_secondary_index {
    name               = "CategoryIndex"
    hash_key           = "category"
    projection_type    = "ALL"
    write_capacity     = 0
    read_capacity      = 0
  }
  
  tags = {
    Name        = var.inventory_table_name
    Environment = var.environment
  }
  
  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = false // Enable point-in-time recovery if needed
  }
  
  # Enable streams for global tables
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  # Enable global tables v2
  dynamic "replica" {
    for_each = var.dynamodb_replica_regions
    content {
      region_name = replica.value
    }
  }
}