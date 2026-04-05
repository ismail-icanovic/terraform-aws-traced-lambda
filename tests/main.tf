# Test suite for traced_python_lambda module
# Run: terraform plan in this directory

provider "aws" {
  region = "eu-central-1"
}

# Test 1: Basic function with shared layer
module "test_basic" {
  source = "../modules/traced_python_lambda"

  function_name = "test-basic"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "test"

  use_shared_layer = true
}

# Test 2: Function without shared layer
module "test_no_layer" {
  source = "../modules/traced_python_lambda"

  function_name = "test-no-layer"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "test"

  use_shared_layer = false
}

# Test 3: Function with anomaly detector
module "test_anomaly" {
  source = "../modules/traced_python_lambda"

  function_name = "test-anomaly"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "test"

  enable_anomaly_detector = true
}

# Test 4: Function with VPC config
module "test_vpc" {
  source = "../modules/traced_python_lambda"

  function_name = "test-vpc"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "test"

  vpc_security_group_ids = ["sg-12345678"]
  vpc_subnet_ids         = ["subnet-12345678"]
}

# Test 5: Function with custom policies
module "test_policies" {
  source = "../modules/traced_python_lambda"

  function_name = "test-policies"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "test"

  attach_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  inline_policies = [jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:GetItem"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })]
}
