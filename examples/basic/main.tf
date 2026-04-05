provider "aws" {
  region = "eu-central-1"
}

module "hello_world" {
  source = "../../modules/traced_python_lambda"

  function_name = "hello-world"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "default"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  enable_anomaly_detector = false
}

module "data_processor" {
  source = "../../modules/traced_python_lambda"

  function_name    = "data-processor"
  handler          = "app.handler"
  runtime          = "python3.13"
  architecture     = "arm64"
  environment      = "default"
  use_shared_layer = false
}

module "api_handler" {
  source = "../../modules/traced_python_lambda"

  function_name = "api-handler"
  handler       = "app.handler"
  runtime       = "python3.12"
  architecture  = "x86_64"
  environment   = "default"

  environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  enable_anomaly_detector = true
}
