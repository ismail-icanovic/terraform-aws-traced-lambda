data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  function_name    = var.function_name
  shared_path      = abspath("${path.root}/../python_lambda_functions")
  layer_hash       = md5(filemd5("${local.shared_path}/pyproject.toml"))
  dist_path        = "${local.shared_path}/.dist"
  architecture     = var.architecture == "arm64" ? "aarch64" : "x86_64"
  platform         = var.architecture == "arm64" ? "manylinux2014_aarch64" : "manylinux2014_x86_64"
  layer_file       = "${local.dist_path}/layer-${local.function_name}.zip"
  function_file    = "${local.dist_path}/function-${local.function_name}.zip"
  aws_region       = data.aws_region.current.region
  artifacts_bucket = "terraform-modules-${data.aws_caller_identity.current.account_id}-${local.aws_region}"
}

resource "null_resource" "build_layer" {
  count = var.use_shared_layer ? 1 : 0

  triggers = {
    layer_hash = local.layer_hash
  }

  provisioner "local-exec" {
    command     = <<EOT
      cd ${local.shared_path}
      mkdir -p .dist
      rm -f ${local.layer_file}
      python3 -m pip install --platform ${local.platform} --only-binary=:all: -t python -r pyproject.toml 2>/dev/null || true
      cd python
      zip -q -r ${local.layer_file} .
      rm -rf python
      aws s3 cp ${local.layer_file} s3://${local.artifacts_bucket}/layers/ --region ${local.aws_region}
EOT
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "build_function" {
  count = 1

  triggers = {
    hash = filemd5("${local.shared_path}/pyproject.toml")
  }

  provisioner "local-exec" {
    command     = <<EOT
      cd ${local.shared_path}
      mkdir -p .dist
      rm -f ${local.function_file}
      cd ${var.function_path}/${local.function_name}
      zip -q -r ${local.function_file} . -x "*.sh"
      aws s3 cp ${local.function_file} s3://${local.artifacts_bucket}/functions/ --region ${local.aws_region}
EOT
    interpreter = ["bash", "-c"]
  }
}

resource "aws_lambda_layer_version" "shared" {
  count = var.use_shared_layer ? 1 : 0

  depends_on = [null_resource.build_layer]

  layer_name               = "shared-dependencies-${local.function_name}"
  compatible_architectures = [var.architecture]
  compatible_runtimes      = [var.runtime]
  s3_bucket                = local.artifacts_bucket
  s3_key                   = "layers/layer-${local.function_name}.zip"
}

resource "aws_lambda_function" "this" {
  depends_on = [null_resource.build_function]

  function_name = local.function_name
  role          = aws_iam_role.this.arn
  handler       = var.handler
  runtime       = var.runtime
  architectures = [var.architecture]
  memory_size   = var.memory_size
  timeout       = var.timeout
  s3_bucket     = local.artifacts_bucket
  s3_key        = "functions/function-${local.function_name}.zip"

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [var.environment_variables] : []
    content {
      variables = environment.value
    }
  }

  dynamic "ephemeral_storage" {
    for_each = [var.ephemeral_storage_size]
    content {
      size = ephemeral_storage.value
    }
  }

  layers = var.use_shared_layer ? concat(var.extra_layers, [aws_lambda_layer_version.shared[0].arn]) : var.extra_layers

  dynamic "logging_config" {
    for_each = var.log_level != null ? [var.log_level] : []
    content {
      log_format            = "JSON"
      application_log_level = logging_config.value
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [var.tracing_mode] : []
    content {
      mode = tracing_config.value
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_security_group_ids) > 0 ? [{
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.vpc_subnet_ids
    }] : []
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }
}

resource "aws_lambda_alias" "this" {
  count = var.create_alias ? 1 : 0

  name             = var.alias_name
  function_name    = aws_lambda_function.this.function_name
  function_version = "$LATEST"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_id
}

resource "aws_iam_role" "this" {
  name = "lambda-exec-${local.function_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_role_policy" "inline" {
  count = length(var.inline_policies)

  name   = length(var.inline_policies) == 1 ? "lambda-policy" : "lambda-policy-${count.index + 1}"
  role   = aws_iam_role.this.id
  policy = var.inline_policies[count.index]
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "custom" {
  count      = length(var.attach_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = var.attach_policy_arns[count.index]
}

resource "aws_lambda_permission" "this" {
  count = length(var.allowed_triggers) > 0 ? length(var.allowed_triggers) : 0

  statement_id  = "AllowExecutionFrom${replace(var.allowed_triggers[count.index].source, ".", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = var.allowed_triggers[count.index].source
  source_arn    = var.allowed_triggers[count.index].source_arn
}
