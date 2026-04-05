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
  source = "ismailicanovic/traced-lambda/aws"
  version = "1.0.0"

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
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
|------|-------------|
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_name | Name of the Lambda function |
| lambda_role_arn | ARN of the IAM role |
| log_group_name | Name of the CloudWatch log group |
| layer_arn | ARN of the shared layer (if enabled) |

## Publishing to AWS CodeArtifact

```bash
# Get CodeArtifact credentials
aws codeartifact get-authorization-token --domain smart-things --domain-owner 124355683078 --region us-east-1

# Configure Terraform credentials
cat > ~/.terraform.d/credentials.tfrc.json <<EOF
{
  "credentials": {
    "arn:aws:codeartifact:us-east-1:124355683078:domain/smart-things": {
      "token": "$(aws codeartifact get-authorization-token --domain smart-things --domain-owner 124355683078 --query authorizationToken --output text)",
      "expires": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
  }
}
EOF
```

Then add to your module source:

```hcl
source = "arn:aws:codeartifact:us-east-1:124355683078:package/smart-things/terraform-modules/null/versions/1.0.0/null"
```
# terraform-aws-traced-lambda
