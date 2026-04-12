data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  function_name     = var.function_name
  shared_path       = abspath("${path.root}/../python_lambda_functions")
  dist_path         = "${local.shared_path}/.dist"
  requirements_file = "${local.shared_path}/requirements.txt"
  requirements_hash = filemd5(local.requirements_file)
  sync_script_hash  = filemd5("${path.module}/scripts/sync_dependencies.sh")
  lambda_pythonpath = contains(keys(var.environment_variables), "PYTHONPATH") ? "${var.environment_variables["PYTHONPATH"]}:/var/task/.dependencies:/var/task" : "/var/task/.dependencies:/var/task"

  function_files = sort([
    for f in fileset("${local.shared_path}/${local.function_name}", "**") : "${local.function_name}/${f}"
    if !contains(split("/", f), "__pycache__") &&
    !endswith(f, ".pyc") &&
    !endswith(f, ".pyo") &&
    !endswith(f, ".DS_Store")
  ])

  shared_files = sort([
    for f in fileset("${local.shared_path}/shared", "**") : "shared/${f}"
    if !contains(split("/", f), "__pycache__") &&
    !endswith(f, ".pyc") &&
    !endswith(f, ".pyo") &&
    !endswith(f, ".DS_Store")
  ])

  package_files = concat(local.function_files, local.shared_files)

  package_hash = sha256(format(
    "%srequirements:%s\n",
    join("", [
      for f in local.package_files : "${f}:${filemd5("${local.shared_path}/${f}")}\n"
    ]),
    local.requirements_hash,
  ))

  function_file    = "${local.dist_path}/function-${local.function_name}-${substr(local.package_hash, 0, 12)}.zip"
  aws_region       = data.aws_region.current.region
  artifacts_bucket = "terraform-modules-${data.aws_caller_identity.current.account_id}-${local.aws_region}"
  function_s3_key  = var.lambda_s3_key != "" ? var.lambda_s3_key : "functions/function-${local.function_name}-${substr(local.package_hash, 0, 12)}.zip"
}

resource "null_resource" "sync_dependencies" {
  triggers = {
    requirements_hash = local.requirements_hash
    sync_script_hash  = local.sync_script_hash
  }

  provisioner "local-exec" {
    command     = <<EOT
      set -euo pipefail
      bash ${path.module}/scripts/sync_dependencies.sh ${local.shared_path}
EOT
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "build_function" {
  triggers = {
    package_hash = local.package_hash
    s3_key       = local.function_s3_key
  }

  provisioner "local-exec" {
    command     = <<EOT
      set -euo pipefail
      mkdir -p ${local.dist_path}
      STAGE_DIR="${local.dist_path}/stage-${local.function_name}"
      rm -rf "$STAGE_DIR"
      mkdir -p "$STAGE_DIR"
      rsync -a ${local.shared_path}/shared/ "$STAGE_DIR/shared/"
      rsync -a ${local.shared_path}/.dependencies/ "$STAGE_DIR/.dependencies/"
      rsync -a ${local.shared_path}/${local.function_name}/ "$STAGE_DIR/"
      rm -f ${local.dist_path}/function-${local.function_name}-*.zip
      cd "$STAGE_DIR"
      zip -q -r ${local.function_file} . -x "__pycache__/*" "**/__pycache__/*" "*.pyc" "*.pyo" ".DS_Store" "**/.DS_Store"
      aws s3 cp ${local.function_file} s3://${local.artifacts_bucket}/${local.function_s3_key} --region ${local.aws_region}
      rm -rf "$STAGE_DIR"
EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [null_resource.sync_dependencies]
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = aws_iam_role.this.arn
  handler       = var.handler
  runtime       = var.runtime
  architectures = [var.architecture]
  memory_size   = var.memory_size
  timeout       = var.timeout
  s3_bucket     = local.artifacts_bucket
  s3_key        = local.function_s3_key

  s3_object_version = var.lambda_s3_object_version != "" ? var.lambda_s3_object_version : null

  environment {
    variables = merge(var.environment_variables, {
      PYTHONPATH = local.lambda_pythonpath
    })
  }

  dynamic "ephemeral_storage" {
    for_each = [var.ephemeral_storage_size]
    content {
      size = ephemeral_storage.value
    }
  }

  layers = var.extra_layers

  dynamic "logging_config" {
    for_each = var.log_level != null ? [var.log_level] : []
    content {
      log_format            = "JSON"
      application_log_level = logging_config.value
    }
  }

  tracing_config {
    mode = "Active"
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

  depends_on = [null_resource.build_function]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_id
}

resource "aws_cloudwatch_log_anomaly_detector" "this" {
  detector_name      = "${local.function_name}-anomaly-detector"
  log_group_arn_list = [aws_cloudwatch_log_group.this.arn]
}

resource "aws_iam_role" "this" {
  name = "lambda-exec-${local.function_name}-${var.environment}"

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
