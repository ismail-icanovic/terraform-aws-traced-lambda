---
name: traced-python-lambda-module-manager
description: "Manage the traced_python_lambda Terraform module in this repo. Use for adding/changing Lambda features, variables, outputs, IAM policies, triggers, logging/tracing, layer packaging, docs/tests sync, and edge-case validation."
argument-hint: "Describe the module change, expected behavior, and whether it is breaking."
user-invocable: true
---

# Traced Python Lambda Module Manager

## Goal
Maintain `modules/traced_python_lambda` safely, keep behavior predictable, and keep code/docs/tests in sync.

## Read First (Always)
1. `modules/traced_python_lambda/variables.tf`
2. `modules/traced_python_lambda/main.tf`
3. `modules/traced_python_lambda/outputs.tf`
4. `tests/main.tf`
5. `README.md`
6. `versions.tf`

## Module Functionality (Complete)
1. Builds and uploads Lambda code zip to S3 via `null_resource.build_function`.
2. Optionally builds/uploads shared dependency layer zip via `null_resource.build_layer`.
3. Creates Lambda function from S3 object.
4. Optionally adds extra layers and shared layer.
5. Optionally creates Lambda alias.
6. Creates CloudWatch log group with retention and optional KMS key.
7. Creates IAM execution role.
8. Attaches AWSLambdaBasicExecutionRole.
9. Attaches extra managed policy ARNs.
10. Attaches inline JSON policies as `aws_iam_role_policy` resources.
11. Creates per-trigger `aws_lambda_permission` entries.
12. Supports optional dynamic blocks: environment, logging config, tracing config, VPC config, ephemeral storage.

## Inputs (Complete Contract)
### Identity and runtime
- `function_name` (required): Lambda name and base artifact naming key.
- `handler` (default `app.handler`): Lambda handler.
- `runtime` (default `python3.13`): validated to `python3.12|python3.13|python3.14`.
- `architecture` (default `arm64`): validated to `arm64|x86_64`.
- `memory_size` (default `512`): Lambda memory MB.
- `timeout` (default `30`): Lambda timeout seconds.
- `environment` (default `default`): used in IAM role name.

### Lambda settings
- `environment_variables` (default `{}`): if empty, no environment block is emitted.
- `log_level` (default `null`): if set, emits `logging_config` JSON log format.
- `tracing_mode` (default `null`): if set, emits `tracing_config` mode.
- `ephemeral_storage_size` (default `512`): always emitted as `ephemeral_storage` size.

### Networking
- `vpc_security_group_ids` (default `[]`): enables VPC block when non-empty.
- `vpc_subnet_ids` (default `[]`): used with VPC block.

### Layer and code artifacts
- `use_shared_layer` (default `true`): controls shared layer build/resource.
- `extra_layers` (default `[]`): always allowed; merged with shared layer when enabled.
- `aws_region` (default `eu-central-1`): used by local `aws s3 cp` commands.
- `layer_s3_bucket` (default preset bucket): upload/read location for layer zip.
- `lambda_s3_bucket` (default preset bucket): upload/read location for function zip.
- `lambda_s3_key` (default empty): currently not used by resources.
- `lambda_s3_object_version` (default empty): currently not used by resources.
- `function_path` (default `.`): base path that resolves to `<function_path>/<function_name>` during packaging.

### Versioning and alias
- `create_alias` (default `false`): creates alias when true.
- `alias_name` (default `live`): alias name when alias creation is enabled.

### IAM
- `attach_policy_arns` (default `[]`): managed policy attachments.
- `inline_policies` (default `[]`): list of JSON policy strings attached as role policies.
- `permissions_boundary_arn` (default `null`): optional role permissions boundary.

### Optional integration
- `enable_anomaly_detector` (default `false`): input exists but is currently not used by resources.
- `allowed_triggers` (default `[]`): list of `{ source, source_arn }` for invoke permissions.

## Outputs (Complete Contract)
- `lambda_function_arn`
- `lambda_function_name`
- `lambda_role_arn`
- `lambda_role_name`
- `log_group_name`
- `layer_arn` (null when shared layer disabled)
- `alias_arn` (null when alias disabled)

## Required Edit Rules
1. Keep input/output contract synchronized across:
   - `variables.tf`
   - `main.tf`
   - `outputs.tf`
   - `README.md` Inputs/Outputs tables
   - `tests/main.tf` scenario coverage
2. Never reintroduce deprecated `aws_iam_role.inline_policy`; use `aws_iam_role_policy` resources.
3. Keep default behavior non-breaking unless user asks for breaking changes.
4. Preserve existing naming patterns for resources and artifacts unless change is intentional and documented.

## Change Procedure
1. Classify request:
   - New capability
   - Bug fix
   - Refactor/no behavior change
   - Breaking change
2. Map affected areas:
   - Runtime config -> `variables.tf`, `main.tf`, README
   - IAM/triggers -> `main.tf`, tests
   - Packaging/layer -> locals + `null_resource` + docs
   - Outputs -> `outputs.tf`, README
3. Apply minimal edits only in required files.
4. Add or update at least one test scenario in `tests/main.tf` for each new branch/path.
5. Run validation commands.
6. Report exactly what changed and any residual risk.

## Validation Commands
Run from repo root unless `-chdir` is used:
1. `terraform fmt -recursive`
2. `terraform -chdir=tests init`
3. `terraform -chdir=tests validate`
4. `terraform -chdir=tests plan` (if AWS credentials/environment are available)

## Edge Cases Checklist (Do Not Skip)
1. `runtime` and `architecture` remain within validated values.
2. `create_alias=false` keeps `alias_arn` null and avoids alias resource creation.
3. `use_shared_layer=false` keeps `layer_arn` null and skips layer resource.
4. Empty `environment_variables` omits environment block.
5. `log_level=null` omits logging config.
6. `tracing_mode=null` omits tracing config.
7. VPC block appears only when security groups are provided; verify subnet compatibility when VPC is enabled.
8. `inline_policies` values must be valid JSON policy documents.
9. `allowed_triggers` principals/source ARNs are valid for target service.
10. Packaging paths resolve correctly from `path.root` and `function_path`.
11. Local build/upload steps require local tools (`python3`, `pip`, `zip`, `aws`) and bucket access.
12. Hardcoded S3 keys (`layers/layer-<name>.zip`, `functions/function-<name>.zip`) still match upload commands.
13. `enable_anomaly_detector`, `lambda_s3_key`, and `lambda_s3_object_version` are currently declared but not wired; keep this explicit in docs until implemented.

## Done Criteria
1. Terraform code formats cleanly.
2. `tests/main.tf` still covers baseline and new/changed paths.
3. README contract matches real module contract.
4. No deprecated IAM inline policy pattern is introduced.
5. Any intentional breaking change is explicitly documented.
