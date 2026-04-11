# terraform-aws-traced-lambda

A reusable Terraform module for deploying Python Lambda functions with:

- Shared dependencies layer (AWS Lambda Powertools, X-Ray)
- Type-safe architecture and runtime validation
- CloudWatch logging with optional anomaly detection
- X-Ray tracing support
- VPC configuration support
- Flexible IAM policies

## Usage

```hcl
module "my_lambda" {
  source = "github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=v1.0.0"

  function_name = "my-function"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  environment   = "prod"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  enable_anomaly_detector = true
}
```

## Versioning

This module uses Git tags for versioning. Use the `ref` parameter to pin to a specific version:

```hcl
source = "github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=v1.0.0"
```

Check the [releases page](https://github.com/ismail-icanovic/terraform-aws-traced-lambda/releases) for available versions.

## Local Merge Flow

Use these commands to merge `pre-release` into `main` locally and push `main` upstream:

```bash
git fetch origin
git checkout main
git pull --ff-only origin main
git merge --no-ff pre-release
git push origin main
```

## Artifact Resolution

- The module inherits the AWS region from the configured AWS provider.
- The artifact S3 bucket is derived automatically as `terraform-modules-<account-id>-<region>`.
- Consumers do not need to pass region or artifact bucket inputs.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| function_name | Name of the Lambda function | `string` | - | yes |
| handler | Handler for the Lambda function | `string` | `"app.handler"` | no |
| runtime | Lambda runtime (python3.12, python3.13, python3.14) | `string` | `"python3.13"` | no |
| architecture | Lambda architecture (arm64, x86_64) | `string` | `"arm64"` | no |
| memory_size | Memory allocation in MB | `number` | `512` | no |
| timeout | Timeout in seconds | `number` | `30` | no |
| environment | Environment name (dev, staging, prod) | `string` | `"default"` | no |
| use_shared_layer | Whether to use the shared dependencies layer | `bool` | `true` | no |
| enable_anomaly_detector | Enable CloudWatch Log Anomaly Detector | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_name | Name of the Lambda function |
| lambda_role_arn | ARN of the IAM role |
| log_group_name | Name of the CloudWatch log group |
| layer_arn | ARN of the shared layer (if enabled) |
