---
name: traced-python-lambda-module-consumer
description: "Guide users consuming traced_python_lambda: how to import/use the module, where to place Lambda code, what each option enables, and which configuration path to choose. Use when user says use this module."
argument-hint: "Provide function name, environment, and needed features (VPC, layer, IAM, triggers, alias, logging/tracing)."
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
The current module packaging logic expects this structure relative to Terraform root:
1. Dependency file in `../python_lambda_functions/pyproject.toml`
2. Function code in `../python_lambda_functions/<function_name>/`
3. Handler file usually `app.py` with `handler` function

Example for `function_name = "orders-api"`:
1. `../python_lambda_functions/pyproject.toml`
2. `../python_lambda_functions/orders-api/app.py`

## Terraform Import and Basic Usage
Use module source import:
1. Remote source: `github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=<tag>`
2. Local source in this repo: `../modules/traced_python_lambda`

Minimal module block fields:
1. `function_name` required
2. Optional commonly set: `environment`, `runtime`, `architecture`

## Ready Templates
### Minimal module template
```hcl
module "my_lambda" {
   source = "github.com/ismail-icanovic/terraform-aws-traced-lambda//modules/traced_python_lambda?ref=v1.0.0"

   function_name = "my-function"
   environment   = "dev"
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
   environment   = "prod"
   memory_size   = 512
   timeout       = 30

   environment_variables = {
      LOG_LEVEL = "INFO"
   }

   tracing_mode = "Active"
   log_level    = "INFO"

   create_alias = true
   alias_name   = "live"

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
<terraform-root>/../python_lambda_functions/pyproject.toml
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
- `tracing_mode`: emits X-Ray tracing config.
- `log_retention_days`: CloudWatch retention.
- `log_group_kms_key_id`: encrypt logs with KMS.

### Networking
- `vpc_security_group_ids`, `vpc_subnet_ids`: enable VPC execution.

### Layers and dependencies
- `use_shared_layer`: build/use shared dependency layer.
- `extra_layers`: add more layer ARNs.
- Dependencies for shared layer come from `../python_lambda_functions/pyproject.toml`.

### Packaging and S3
- `layer_s3_bucket`, `lambda_s3_bucket`, `aws_region`: upload and publish artifacts.
- `function_path`: base path for `<function_path>/<function_name>` during packaging.
- `lambda_s3_key`, `lambda_s3_object_version`: currently declared inputs, not wired in function resource path/version.

### Release and routing
- `create_alias`, `alias_name`: optional Lambda alias.

### IAM and permissions
- `attach_policy_arns`: attach managed policies.
- `inline_policies`: attach JSON inline policies.
- `permissions_boundary_arn`: role boundary.

### Invocation sources
- `allowed_triggers`: list of `{ source, source_arn }` to create invoke permissions.

### Declared but not wired
- `enable_anomaly_detector`: currently no resource uses it.

## Consumer Paths (Choose One)
1. Minimal path:
   - Set `function_name` and `environment`.
   - Place code in `../python_lambda_functions/<function_name>/app.py`.
2. API path:
   - Add `allowed_triggers` for API Gateway principal and ARN.
   - Add `tracing_mode = "Active"`, `log_level = "DEBUG"` if needed.
3. Private/VPC path:
   - Set `vpc_security_group_ids` and `vpc_subnet_ids`.
   - Ensure networking allows AWS service egress where required.
4. No shared-layer path:
   - Set `use_shared_layer = false`.
   - Ensure function package includes everything it needs.
5. IAM-custom path:
   - Add `attach_policy_arns` and/or `inline_policies`.
   - Keep least privilege.

## Python Code Placement and Handler Rules
1. Module zips files from `<function_path>/<function_name>`.
2. Default `handler = "app.handler"` means:
   - File: `app.py`
   - Callable: `def handler(event, context):`
3. If handler changes, file/function names must match handler string.
4. Keep deployment folder flat unless handler path reflects subpackages.

## Dependencies and Imports
1. Shared-layer dependencies are installed from `../python_lambda_functions/pyproject.toml`.
2. If using Powertools/X-Ray from shared layer, import them in function code directly.
3. If `use_shared_layer = false`, dependencies must be included another way.

## Packaging Behavior (Current)
1. Module packaging creates `../python_lambda_functions/.dist` automatically.
2. Function and layer resources now wait for build/upload steps to complete before publish/create.
3. If artifact upload fails, expect the failure in build/provisioner output first (instead of later `NoSuchKey` errors).

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
3. Missing local tools for packaging (`python3`, `pip`, `zip`, `aws`).
4. Missing S3 permissions or wrong bucket/region.
5. Invalid inline policy JSON.
6. Invalid trigger principal/source ARN pairing.
7. Expecting behavior from inputs that are currently not wired (`enable_anomaly_detector`, `lambda_s3_key`, `lambda_s3_object_version`).

## Agent Response Contract
When asked to use this module, always return:
1. Exact module block with required and selected optional fields.
2. Exact file tree to create.
3. Exact handler location and function signature.
4. Exact dependency location (`pyproject.toml`) and how it affects layer build.
5. Chosen option rationale in short bullets.
6. Validation commands.
