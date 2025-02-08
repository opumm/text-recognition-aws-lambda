terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "opu"
  region  = var.region  # Use the variable for region
}

# Declare region variable
variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"  # Set default region or override in terraform.tfvars
}

# Data source for account ID
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
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
}

resource "aws_iam_policy" "rekognition_policy" {
  name        = "rekognition-policy"
  description = "Allows Rekognition to access resources"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "rekognition:DetectText"
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "proxy_lambda_invoke_policy" {
  name        = "proxy-lambda-invoke-policy"
  description = "Allow ProxyLambda to invoke TextRecognitionLambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:TextRecognitionLambda"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rekognition_attachment" {
  policy_arn = aws_iam_policy.rekognition_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "proxy_lambda_invoke_attachment" {
  policy_arn = aws_iam_policy.proxy_lambda_invoke_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_policy" "textract_policy" {
  name        = "TextractAccessPolicy"
  description = "Allows Lambda to use Amazon Textract"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = "textract:DetectDocumentText"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_textract_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.textract_policy.arn
}


# Define common Lambda function properties
locals {
  lambda_runtime = "python3.9"
  lambda_timeout = 30
  lambda_memory  = 512
  lambda_package = "lambda-package.zip"
}

resource "aws_lambda_function" "proxy_lambda" {
  filename      = local.lambda_package
  function_name = "ProxyLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "proxy.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory
  timeout       = local.lambda_timeout
  depends_on    = [aws_iam_role_policy_attachment.rekognition_attachment, aws_iam_role_policy_attachment.proxy_lambda_invoke_attachment]
}

resource "aws_lambda_function" "text_recognition_lambda" {
  filename      = local.lambda_package
  function_name = "TextRecognitionLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "text_recognition.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory
  timeout       = local.lambda_timeout
  depends_on    = [aws_iam_role_policy_attachment.rekognition_attachment]
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "TextRecognitionAPI"
  description = "API for Text Recognition Service"
}

resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "text-recognition"
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.proxy_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.proxy_lambda.function_name
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on  = [aws_api_gateway_integration.proxy_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/prod"
}
