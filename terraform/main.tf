data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

# API Gateway
resource "aws_iam_role" "api_gw_cloudwatch_role" {
  name = "ApiGwCloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gw_cloudwatch_policy" {
  name = "ApiGwCloudWatchPolicy"
  role = aws_iam_role.api_gw_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${aws_api_gateway_rest_api.rest_api.name}:*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "api_gw_log_group" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.rest_api.name}"
  retention_in_days = 14
}

resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "BatchComputeAPI"
  description = "REST API for BatchCompute Service"
}

resource "aws_api_gateway_resource" "extract_data" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "extract-data"
}

resource "aws_api_gateway_authorizer" "custom_lambda_authorizer" {
  name                   = "custom_lambda_authorizer"
  rest_api_id            = aws_api_gateway_rest_api.rest_api.id
  authorizer_uri         = aws_lambda_function.custom_authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.api_gateway_authorizer_role.arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.X-API-Secret"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.extract_data.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_lambda_authorizer.id  # Reference the custom authorizer here
  
  request_parameters = {
    "method.request.header.X-API-Secret" = true
  }
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.extract_data.id
  http_method = aws_api_gateway_method.post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.batch_proxy.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on  = [aws_api_gateway_method.post, aws_api_gateway_integration.lambda]
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_log_group.arn
    format          = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}
