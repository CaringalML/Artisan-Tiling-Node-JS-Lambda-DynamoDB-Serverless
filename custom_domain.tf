# ACM Certificate for Custom Domain
resource "aws_acm_certificate" "api_cert" {
  domain_name       = var.api_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.api_domain_name}-certificate"
    Environment = var.environment
  }
}

# Custom Domain Name for API Gateway
resource "aws_api_gateway_domain_name" "api_domain" {
  domain_name              = var.api_domain_name
  regional_certificate_arn = aws_acm_certificate.api_cert.arn
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = var.api_domain_name
    Environment = var.environment
  }

  depends_on = [aws_acm_certificate_validation.cert_validation]
}

# API Gateway Base Path Mapping
resource "aws_api_gateway_base_path_mapping" "api_mapping" {
  api_id      = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  domain_name = aws_api_gateway_domain_name.api_domain.domain_name
}