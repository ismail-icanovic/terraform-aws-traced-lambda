# terraform-aws-traced-lambda

A reusable Terraform module for deploying Python Lambda functions with:

- Full-source packaging (no managed Lambda layers)
- Shared Python code via a common `python_lambda_functions/shared` package
- Vendored dependencies bundled directly in each Lambda zip
- Type-safe architecture and runtime validation
- CloudWatch logging with always-on anomaly detection
- X-Ray tracing always enabled (`Active`)
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
}
```

## Packaging Model

- The module builds a minimal package for each Lambda deployment.
- Each package includes only:
  - the selected function folder contents promoted to zip root (for `app.handler`, including any nested files/folders),
  - `shared/`,
  - `.dependencies/`.
- The module does not create or publish Lambda layers.
- Each Lambda handler is set directly in Terraform.
- The module overlays `<function_name>/` onto package root during packaging, so `app.handler` and sibling imports work per function.
- The module sets `PYTHONPATH` automatically to include `/var/task/.dependencies`.

### Dependency Sync

Dependencies are defined in `python_lambda_functions/requirements.txt`.

Dependency syncing is managed by the Terraform module before packaging and upload.
The module executes its internal script at `modules/traced_python_lambda/scripts/sync_dependencies.sh`,
which installs dependencies into `python_lambda_functions/.dependencies`.
The sync script is concurrency-safe (lock + hash check), so repeated module instances do not race on dependency installation.

Consumers of the module do not need to run a separate dependency sync command.
Consumers also do not need to add helper code in Lambda handlers for dependency path setup.

Example for a function named `api-handler`:

```hcl
function_name = "api-handler"
handler       = "app.handler"
```

## Versioning

This module uses Git tags for versioning. Use the `ref` parameter to pin to a specific version:

```hcl
source = "github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=v1.0.0"
```

Check the [releases page](https://github.com/ismail-icanovic/terraform-aws-traced-lambda/releases) for available versions.

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
| environment_variables | Environment variables for the Lambda | `map(string)` | `{}` | no |
| log_level | Log level (DEBUG, INFO, WARN, ERROR) | `string` | `null` | no |
| log_retention_days | CloudWatch log retention in days | `number` | `14` | no |
| log_group_kms_key_id | KMS key ID for log group encryption | `string` | `null` | no |
| ephemeral_storage_size | Ephemeral storage size in MB (max 10240) | `number` | `512` | no |
| vpc_security_group_ids | VPC security group IDs | `list(string)` | `[]` | no |
| vpc_subnet_ids | VPC subnet IDs | `list(string)` | `[]` | no |
| extra_layers | Additional Lambda layers | `list(string)` | `[]` | no |
| lambda_s3_key | S3 key for Lambda function code | `string` | `""` | no |
| lambda_s3_object_version | S3 object version for Lambda function code | `string` | `""` | no |
| attach_policy_arns | List of policy ARNs to attach to the IAM role | `list(string)` | `[]` | no |
| inline_policies | Inline policies to attach to the IAM role | `list(string)` | `[]` | no |
| permissions_boundary_arn | Permissions boundary ARN for the IAM role | `string` | `null` | no |
| allowed_triggers | List of allowed trigger sources (`source`, `source_arn`) | `list(object)` | `[]` | no |

## Fixed Module Behavior

- X-Ray tracing is always enabled with `mode = "Active"`.
- CloudWatch log anomaly detector is always created for the function log group.
- There is no toggle for tracing mode or anomaly detector.

## Outputs

| Name | Description |
| ---- | ----------- |
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_name | Name of the Lambda function |
| lambda_role_arn | ARN of the IAM role |
| lambda_role_name | Name of the IAM role |
| log_group_name | Name of the CloudWatch log group |
| layer_arn | Always `null` (kept only for backward compatibility) |
