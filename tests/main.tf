# Single plan playground for traced_python_lambda module
# Run: terraform init && terraform plan in this directory

provider "aws" {
  region = "us-west-2"
}

locals {
  aws_account_id = "124355683078"
  inline_policy_read_dynamodb = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:GetItem"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# 1) Base path: full package, arm64, alias creation
module "hello_world" {
  source = "../modules/traced_python_lambda"

  function_name = "hello-world"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }
}

# 2) Data processor path
module "data_processor" {
  source = "../modules/traced_python_lambda"

  function_name = "data-processor"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
}

# 3) x86_64 + tracing/logging/trigger permission path
module "api_handler" {
  source = "../modules/traced_python_lambda"

  function_name = "api-handler"
  handler       = "app.handler"
  runtime       = "python3.12"
  architecture  = "x86_64"
  log_level     = "DEBUG"

  environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  allowed_triggers = [{
    source     = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:us-west-2:${local.aws_account_id}:example/*/*/*"
  }]
}

# 4) Minimal inputs only (defaults path)
module "test_basic" {
  source = "../modules/traced_python_lambda"

  function_name = "test-basic"
  handler       = "app.handler"
}

# 5) Small memory profile
module "test_no_layer" {
  source = "../modules/traced_python_lambda"

  function_name = "test-no-layer"
  handler       = "app.handler"
  memory_size   = 256
}

# 6) Logging/tracing edge config + anomaly toggle input
module "test_anomaly" {
  source = "../modules/traced_python_lambda"

  function_name          = "test-anomaly"
  handler                = "app.handler"
  log_level              = "ERROR"
  ephemeral_storage_size = 1024
}

# 7) IAM attachment + inline policy path
module "test_policies" {
  source = "../modules/traced_python_lambda"

  function_name = "test-policies"
  handler       = "app.handler"

  attach_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  inline_policies = [
    local.inline_policy_read_dynamodb
  ]
}
