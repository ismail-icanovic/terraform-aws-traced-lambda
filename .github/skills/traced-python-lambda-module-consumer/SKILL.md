---
name: traced-python-lambda-module-consumer
description: "Guide users consuming traced_python_lambda: module usage, folder layout, handlers, dependency model, and validation. Use when user says use this module."
argument-hint: "Provide function name and needed features (VPC, IAM, triggers, logging, policies)."
user-invocable: true
---

# Traced Python Lambda Module Consumer Guide

## Goal
Help users consume the module correctly on first try: source import, code placement, options, and validation.

## Use When
- User says: use this module.
- User asks: what options exist.
- User asks: where to place code/dependencies.
- User asks: minimal vs advanced setup.

## Required Folder Layout
The current module expects this structure relative to Terraform root:
1. Dependency file in `../python_lambda_functions/requirements.txt`
2. Shared code in `../python_lambda_functions/shared/`
3. Function code in `../python_lambda_functions/<function_name>/`
4. Handler file usually `app.py` with `handler` function

Example for `function_name = "orders-api"`:
1. `../python_lambda_functions/requirements.txt`
2. `../python_lambda_functions/shared/`
3. `../python_lambda_functions/orders-api/app.py`

## Terraform Import and Basic Usage
Use module source import:
1. Remote source: `github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=<tag>`
2. Local source in this repo: `../modules/traced_python_lambda`

Minimal module block fields:
1. `function_name` required
2. Optional commonly set: `handler`, `runtime`, `architecture`, `memory_size`, `timeout`

## Ready Templates
### Minimal module template
```hcl
module "my_lambda" {
  source = "github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=v1.0.0"

  function_name = "my-function"
}
```

### Common production template
```hcl
module "orders_api" {
  source = "github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=v1.0.0"

  function_name = "orders-api"
  handler       = "app.handler"
  runtime       = "python3.13"
  architecture  = "arm64"
  memory_size   = 512
  timeout       = 30

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  log_level    = "INFO"

  attach_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  allowed_triggers = [{
    source     = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:eu-central-1:123456789012:api-id/*/*/*"
  }]
}
```

### Expected file tree template
```text
<terraform-root>/
<terraform-root>/../python_lambda_functions/
<terraform-root>/../python_lambda_functions/requirements.txt
<terraform-root>/../python_lambda_functions/shared/
<terraform-root>/../python_lambda_functions/orders-api/app.py
```

### Handler template
```python
def handler(event, context):
    return {"statusCode": 200, "body": "ok"}
```

## Option Map (What You Can Configure)
### Core runtime
- `function_name`: resource and artifact naming anchor.
- `handler`: entrypoint, default `app.handler`.
- `runtime`: `python3.12|python3.13|python3.14`.
- `architecture`: `arm64|x86_64`.
- `memory_size`, `timeout`: performance profile.

### Function behavior
- `environment_variables`: Lambda env vars.
- `ephemeral_storage_size`: `/tmp` size in MB.

### Observability
- `log_level`: emits Lambda `logging_config` with JSON log format.
- `log_retention_days`: CloudWatch retention.
- `log_group_kms_key_id`: encrypt logs with KMS.

### Observability defaults (always on)
- X-Ray tracing is always enabled (`Active`).
- CloudWatch Log Anomaly Detector is always created for the Lambda log group.

### Networking
- `vpc_security_group_ids`, `vpc_subnet_ids`: enable VPC execution.

### Dependencies
- Dependencies come from `../python_lambda_functions/requirements.txt`.
- Terraform runs module-internal script `modules/traced_python_lambda/scripts/sync_dependencies.sh`.
- The script installs packages into `../python_lambda_functions/.dependencies`.
- `PYTHONPATH` is automatically set to include `/var/task/.dependencies`.

### Packaging and S3
- Artifacts bucket is auto-derived as `terraform-modules-<account-id>-<region>`.
- Region is inherited from the configured AWS provider.
- Packaging is minimal per function:
  1. selected function folder content is promoted to zip root,
  2. `shared/`,
  3. `.dependencies/`.
- `lambda_s3_key`, `lambda_s3_object_version`: optional S3 override fields.

### IAM and permissions
- `attach_policy_arns`: attach managed policies.
- `inline_policies`: attach JSON inline policies.
- `permissions_boundary_arn`: role boundary.

### Invocation sources
- `allowed_triggers`: list of `{ source, source_arn }` to create invoke permissions.

## Consumer Paths (Choose One)
1. Minimal path:
   - Set `function_name`.
   - Place code in `../python_lambda_functions/<function_name>/app.py`.
2. API path:
   - Add `allowed_triggers` for API Gateway principal and ARN.
  - Add `log_level = "DEBUG"` if needed.
3. Private/VPC path:
   - Set `vpc_security_group_ids` and `vpc_subnet_ids`.
   - Ensure networking allows AWS service egress where required.
4. IAM-custom path:
   - Add `attach_policy_arns` and/or `inline_policies`.
   - Keep least privilege.

## Python Code Placement and Handler Rules
1. Default `handler = "app.handler"` means:
   - File at package root: `app.py`
   - Callable: `def handler(event, context):`
2. Module promotes selected function folder content to package root at build time.
3. Multiple files/folders inside the selected function folder are supported.
4. If handler changes, file/function names must match handler string.

## Packaging Behavior (Current)
1. Module creates `../python_lambda_functions/.dist` for artifacts/staging.
2. Module syncs dependencies before packaging.
3. Dependency sync is concurrency-safe with lock + hash checks.
4. Function resources wait for build/upload completion before Lambda create/update.

## Validation Steps for Consumers
1. `terraform fmt -recursive`
2. `terraform init`
3. `terraform validate`
4. `terraform plan`

If using this repo test harness, run in `tests/`:
1. `terraform -chdir=tests init`
2. `terraform -chdir=tests validate`
3. `terraform -chdir=tests plan`

## Frequent Failure Points
1. Wrong folder placement for function code.
2. Handler string not matching actual file/function.
3. Missing local tools for packaging (`python3`, `pip`, `zip`, `aws`, `rsync`).
4. Missing S3 permissions or wrong bucket/region.
5. Invalid inline policy JSON.
6. Invalid trigger principal/source ARN pairing.

## Agent Response Contract
When asked to use this module, always return:
1. Exact module block with required and selected optional fields.
2. Exact file tree to create.
3. Exact handler location and function signature.
4. Exact dependency location (`requirements.txt`) and module-managed sync behavior.
5. Chosen option rationale in short bullets.
6. Validation commands.
