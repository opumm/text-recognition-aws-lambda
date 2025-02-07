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
  region  = "us-east-1"
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

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

resource "aws_iam_policy_attachment" "rekognition_policy_attachment" {
  name       = "rekognition-policy-attachment"
  policy_arn = aws_iam_policy.rekognition_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}


resource "aws_lambda_function" "proxy_lambda" {
  filename      = "lambda-package.zip" # Path to the zip of your Proxy Lambda code
  function_name = "ProxyLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "proxy.lambda_handler"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 10
}

resource "aws_lambda_function" "text_recognition_lambda" {
  filename      = "lambda-package.zip" # Path to the zip of your Text Recognition Lambda code
  function_name = "TextRecognitionLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "text_recognition.lambda_handler"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 10
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
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.proxy_lambda.arn}/invocations"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.proxy_lambda.function_name
}
