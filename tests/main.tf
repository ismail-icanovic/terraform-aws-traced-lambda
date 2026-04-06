# Single plan playground for traced_python_lambda module
# Run: terraform init && terraform plan in this directory

provider "aws" {
  region = "eu-central-1"
}

locals {
  inline_policy_read_dynamodb = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:GetItem"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# 1) Base path: shared layer, arm64, alias creation
module "hello_world" {
  source = "../modules/traced_python_lambda"

  function_name = "hello-world"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "test"
  create_alias  = true
  alias_name    = "live"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }
}

# 2) No shared layer path
module "data_processor" {
  source = "../modules/traced_python_lambda"

  function_name = "data-processor"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "test"

  use_shared_layer = false
}

# 3) x86_64 + tracing/logging/trigger permission path
module "api_handler" {
  source = "../modules/traced_python_lambda"

  function_name = "api-handler"
  handler       = "app.handler"
  runtime       = "python3.12"
  architecture  = "x86_64"
  environment   = "test"
  tracing_mode  = "Active"
  log_level     = "DEBUG"

  environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  allowed_triggers = [{
    source     = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:eu-central-1:123456789012:example/*/*/*"
  }]
}

# 4) Minimal inputs only (defaults path)
module "test_basic" {
  source = "../modules/traced_python_lambda"

  function_name = "test-basic"
  environment   = "test"
}

# 5) Explicit no-layer + small memory profile
module "test_no_layer" {
  source = "../modules/traced_python_lambda"

  function_name    = "test-no-layer"
  environment      = "test"
  use_shared_layer = false
  memory_size      = 256
}

# 6) Logging/tracing edge config + anomaly toggle input
module "test_anomaly" {
  source = "../modules/traced_python_lambda"

  function_name           = "test-anomaly"
  environment             = "test"
  log_level               = "ERROR"
  tracing_mode            = "PassThrough"
  enable_anomaly_detector = true
  ephemeral_storage_size  = 1024
}

# 7) IAM attachment + inline policy path
module "test_policies" {
  source = "../modules/traced_python_lambda"

  function_name = "test-policies"
  environment   = "test"

  attach_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  inline_policies = [
    local.inline_policy_read_dynamodb
  ]
}
