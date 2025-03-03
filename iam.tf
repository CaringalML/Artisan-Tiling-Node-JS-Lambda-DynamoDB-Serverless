# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${replace(var.lambda_function_name, "-", "_")}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# Lambda IAM Policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "${replace(var.lambda_function_name, "-", "_")}_dynamodb_policy"
  description = "IAM policy for Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.contact_form.arn
      }
    ]
  })
}

# Lambda IAM Policy for CloudWatch Logs
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "${replace(var.lambda_function_name, "-", "_")}_cloudwatch_policy"
  description = "IAM policy for Lambda to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach DynamoDB Policy to Role
resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

# Attach CloudWatch Policy to Role
resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}