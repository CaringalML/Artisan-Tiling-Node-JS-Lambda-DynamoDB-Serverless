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

# X-Ray IAM Policy for Lambda
resource "aws_iam_policy" "xray_policy" {
  name        = "${replace(var.lambda_function_name, "-", "_")}_xray_policy"
  description = "IAM policy for Lambda to use X-Ray"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach CloudWatch Policy to Role
resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

# Attach X-Ray Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "xray_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.xray_policy.arn
}

# Lambda IAM Policy for DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "lambda_dynamodb_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Resource = [
          aws_dynamodb_table.inventory.arn,
          "${aws_dynamodb_table.inventory.arn}/index/*"
        ],
        Effect = "Allow"
      }
    ]
  })
}