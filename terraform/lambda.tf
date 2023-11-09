# Create Archives
############################################ LAMBDA FUNCTIONS ############################################
###################### Lambda Layer ######################
data "archive_file" "pyairtable_zip" {
  type        = "zip"
  source_dir = "../src/lambda_layer/"
  output_path = "../src/archives/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "pyairtable_layer" {
  filename   = data.archive_file.pyairtable_zip.output_path
  layer_name = "pyairtable_layer"
  source_code_hash = filebase64sha256(data.archive_file.pyairtable_zip.output_path)

  compatible_runtimes = ["python3.8"]

  lifecycle {
    create_before_destroy = true
  }
}

###################### BATCH PROXY ######################
data "archive_file" "batch_proxy_zip" {
  type        = "zip"
  source_dir = "../src/batch_proxy/"
  output_path = "../src/archives/batch_proxy.zip"
}

# IAM Role for Lambda
resource "aws_cloudwatch_log_group" "batch_proxy_log_group" {
  name              = "/aws/lambda/${var.batch_proxy_fname}"
  retention_in_days = var.log_retention_period
}

resource "aws_iam_role" "batch_proxy_role" {
  name = "batch_proxy_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "batch_proxy_lambda_policy" {
  name = "batch_proxy_log_policy"
  role = aws_iam_role.batch_proxy_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.batch_proxy_fname}:*",
      }
    ]
  })
}

resource "aws_iam_role_policy" "batch_proxy_batch_policy" {
  name = "batch_proxy_batch_job_policy"
  role = aws_iam_role.batch_proxy_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "batch:SubmitJob",
          "batch:DescribeJobs",
          "batch:ListJobs"
        ],
        "Resource": "arn:aws:batch:*:*:*"
      }
    ]
  })
}


resource "aws_lambda_function" "batch_proxy" {
  function_name = var.batch_proxy_fname
  role          = aws_iam_role.batch_proxy_role.arn
  handler       = "handler.handler"
  runtime       = "python3.8"
  filename      = data.archive_file.batch_proxy_zip.output_path
  memory_size   = 128
  timeout       = 30
  environment{
    variables = {
      JOB_QUEUE = var.batch_job_queue_name
      JOB_DEFINITION = var.batch_job_def_name
    }
  }
  
  layers = [aws_lambda_layer_version.pyairtable_layer.arn]
}

resource "aws_lambda_permission" "apigw_batch_proxy_permission" {
  statement_id  = "AllowAPIGatewayInvokeBatchProxy"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.batch_proxy.function_name
  principal     = "apigateway.amazonaws.com"
}


###################### CUSTOM AUTHORIZER ######################
data "archive_file" "custom_authorizer_zip" {
  type        = "zip"
  source_file = "../src/authorizer/authorizer.py"
  output_path = "../src/archives/custom_authorizer.zip"
}

# IAM Role for Lambda
resource "aws_cloudwatch_log_group" "custom_authorizer_log_group" {
  name              = "/aws/lambda/${var.authorizer_fname}"
  retention_in_days = var.log_retention_period
}

resource "aws_iam_role" "custom_authorizer_role" {
  name = "custom_authorizer_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      },    
    ]
  })
}

resource "aws_iam_role_policy" "custom_authorizer_log_policy" {
  name = "custom_authorizer_log_policy"
  role = aws_iam_role.custom_authorizer_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.authorizer_fname}:*",
      }
    ]
  })
}

resource "aws_lambda_function" "custom_authorizer" {
  function_name = var.authorizer_fname
  role          = aws_iam_role.custom_authorizer_role.arn
  handler       = "authorizer.lambda_handler"
  runtime       = "python3.8"
  filename      = data.archive_file.custom_authorizer_zip.output_path
  memory_size   = 128
  timeout       = 30
  environment{
    variables = {
      API_SECRET = var.api_secret
    }
  }
}

resource "aws_lambda_permission" "apigw_custom_authorizer_permission" {
  statement_id  = "AllowAPIGatewayInvokeCustomAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.rest_api.id}/${aws_api_gateway_stage.api_stage.stage_name}/*/*"
}


resource "aws_iam_role" "api_gateway_authorizer_role" {
  name = "api_gateway_authorizer_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_invoke_custom_authorizer" {
  name = "APIGatewayInvokeCustomAuthorizer"
  role = aws_iam_role.api_gateway_authorizer_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "lambda:InvokeFunction",
        Resource = aws_lambda_function.custom_authorizer.arn,
        Effect   = "Allow"
      }
    ]
  })
}
